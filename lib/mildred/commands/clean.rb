require "yaml"
require "open3"
require "digest"
require "net/http"
require "uri"

module Mildred
  module Commands
    class Clean < Command
      desc "Run file organization jobs"
      option :dry_run, alias: "-n", desc: "Preview without making changes"
      option :config, alias: "-c", desc: "Config file path", default: "mildred.yml", type: :string

      IMAGE = "mildred"
      DEFAULT_HOST_GATEWAY = "192.168.64.1"

      def call
        config_path = @options[:config] || @args[0] || "mildred.yml"
        raise Error, "Config file not found: #{config_path}" unless File.exist?(config_path)

        config = YAML.load_file(config_path)
        settings = config.fetch("settings", {})
        jobs = config.fetch("jobs", [])
        raise Error, "No jobs defined in config" if jobs.empty?

        check_container_cli!
        ensure_image!
        check_ollama!(settings)

        jobs.each { |job| run_job(job, settings) }
      end

      private

      def check_container_cli!
        _, status = Open3.capture2("which", "container")
        return if status.success?

        raise Error, "Apple Container CLI not found. Install from https://github.com/apple/container"
      end

      def check_ollama!(settings)
        port = ollama_port(settings)

        # Check localhost first — that's where Ollama is running on the host
        Net::HTTP.start("127.0.0.1", port, open_timeout: 3, read_timeout: 3) do |http|
          http.get("/")
        end

        # Ollama is running, now check it's reachable on the gateway interface
        # (containers connect via the host gateway, not localhost)
        begin
          Net::HTTP.start(DEFAULT_HOST_GATEWAY, port, open_timeout: 3, read_timeout: 3) do |http|
            http.get("/")
          end
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout
          raise Error, <<~MSG.strip
            Ollama is running but only listening on localhost.
            Containers connect via the host gateway (#{DEFAULT_HOST_GATEWAY}), so Ollama must bind to all interfaces.

            Restart Ollama with:
              OLLAMA_HOST=0.0.0.0 ollama serve
          MSG
        end
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout, SocketError
        raise Error, <<~MSG.strip
          Cannot reach Ollama on port #{ollama_port(settings)}.
          Make sure Ollama is running: ollama serve
        MSG
      end

      def image_exists?
        output, status = Open3.capture2("container", "image", "list", "-q")
        status.success? && output.lines.any? { |line| line.strip.start_with?(IMAGE) }
      end

      def container_dir
        @container_dir ||= File.expand_path("../../../container", __dir__)
      end

      def container_source_digest
        files = Dir.glob(File.join(container_dir, "**/*"))
          .select { |f| File.file?(f) && !f.end_with?(".build-digest") }
          .sort
        content = files.map { |f| "#{f}:#{File.read(f)}" }.join
        Digest::SHA256.hexdigest(content)[0, 12]
      end

      def digest_file
        File.join(container_dir, ".build-digest")
      end

      def image_up_to_date?
        return false unless image_exists?
        return false unless File.exist?(digest_file)

        File.read(digest_file).strip == container_source_digest
      end

      def ensure_image!
        return if image_up_to_date?

        reason = image_exists? ? "Source changed. Rebuilding" : "Image not found. Building (first run only)"
        display_info("#{reason}...")
        output, status = nil
        Gum.spin("Building mildred image...", spinner: :dot) do
          output, status = Open3.capture2e("container", "build", "-t", IMAGE, container_dir)
        end
        raise Error, "Build failed:\n#{output.lines.last(5).join}" unless status&.success?

        File.write(digest_file, container_source_digest)
      end

      def ollama_host(settings)
        ollama = settings.dig("ollama") || {}
        ollama.fetch("host", DEFAULT_HOST_GATEWAY)
      end

      def ollama_port(settings)
        ollama = settings.dig("ollama") || {}
        ollama.fetch("port", 11434)
      end

      def ollama_api_base(settings)
        "http://#{ollama_host(settings)}:#{ollama_port(settings)}/v1"
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
          unless status.success?
            unless container_errors.empty?
              $stderr.puts container_errors.last(10).join("\n")
            end
            raise Error, "Container exited with status #{status.exitstatus}"
          end
        end

        display_success("Done")
        puts
      end
    end
  end
end
