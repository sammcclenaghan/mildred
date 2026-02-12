require "yaml"
require "open3"

module Mildred
  module Commands
    class Clean < Command
      desc "Run file organization jobs"
      option :dry_run, alias: "-n", desc: "Preview without making changes"
      option :config, alias: "-c", desc: "Config file path", default: "mildred.yml", type: :string

      IMAGE = "mildred"
      DNS_DOMAIN = "host.container.internal"
      DNS_IP = "203.0.113.113"

      def call
        config_path = @options[:config] || @args[0] || "mildred.yml"
        raise Error, "Config file not found: #{config_path}" unless File.exist?(config_path)

        config = YAML.load_file(config_path)
        settings = config.fetch("settings", {})
        jobs = config.fetch("jobs", [])
        raise Error, "No jobs defined in config" if jobs.empty?

        check_container_cli!
        check_host_dns!
        ensure_image!

        jobs.each { |job| run_job(job, settings) }
      end

      private

      def check_container_cli!
        _, status = Open3.capture2("which", "container")
        return if status.success?

        raise Error, "Apple Container CLI not found. Install from https://github.com/apple/container"
      end

      def host_dns_exists?
        output, status = Open3.capture2("container", "system", "dns", "list")
        status.success? && output.include?(DNS_DOMAIN)
      end

      def check_host_dns!
        return if host_dns_exists?

        raise Error, <<~MSG.strip
          Container DNS not configured. Run this once to allow containers to reach host services:

            sudo container system dns create #{DNS_DOMAIN} --localhost #{DNS_IP}
        MSG
      end

      def image_exists?
        output, status = Open3.capture2("container", "image", "list", "-q")
        status.success? && output.lines.any? { |line| line.strip.start_with?(IMAGE) }
      end

      def ensure_image!
        return if image_exists?

        display_info("Image not found. Building (first run only)...")
        container_dir = File.expand_path("../../../container", __dir__)
        output, status = nil
        Gum.spin("Building mildred image...", spinner: :dot) do
          output, status = Open3.capture2e("container", "build", "-t", IMAGE, container_dir)
        end
        raise Error, "Build failed:\n#{output.lines.last(5).join}" unless status&.success?
      end

      def ollama_api_base(settings)
        ollama = settings.dig("ollama") || {}
        host = ollama.fetch("host", DNS_DOMAIN)
        port = ollama.fetch("port", 11434)
        "http://#{host}:#{port}/v1"
      end

      def model(settings)
        settings.fetch("model", "granite4:latest")
      end

      def run_job(job, settings)
        name = job.fetch("name")
        directory = File.expand_path(job.fetch("directory"))
        tasks = job.fetch("tasks", [])

        raise Error, "Directory does not exist: #{directory}" unless Dir.exist?(directory)
        raise Error, "No tasks defined for job '#{name}'" if tasks.empty?

        display_header(name)

        cmd = [
          "container", "run", "-i", "--rm",
          "--volume", "#{directory}:/workspace",
          "-e", "OLLAMA_API_BASE=#{ollama_api_base(settings)}",
          "-e", "MILDRED_MODEL=#{model(settings)}",
          "-e", "MILDRED_DRY_RUN=#{@options[:dry_run] ? "1" : "0"}",
          IMAGE
        ]

        Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
          container_errors = []
          stderr_reader = Thread.new do
            stderr.each_line do |line|
              if line.include?("Calling tool:")
                tool_name = line.strip.sub("Calling tool: ", "")
                display_step(tool_name)
              else
                container_errors << line.strip
              end
            end
          end

          tasks.each do |task|
            display_info("Task: #{task}")
            stdin.puts task
            stdin.flush
          end
          stdin.close

          stdout.each_line { |line| puts "  #{line}" }
          stderr_reader.join

          status = wait_thread.value
          raise Error, "Container exited with status #{status.exitstatus}" unless status.success?
        end

        display_success("Done")
        puts
      end
    end
  end
end
