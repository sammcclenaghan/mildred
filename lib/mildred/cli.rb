require "yaml"
require "open3"

module Mildred
  class CLI
    IMAGE = "mildred"

    def self.run(args)
      command = args[0]
      config_path = args[1] || "mildred.yml"

      case command
      when "clean"
        new(config_path).clean
      when "build"
        new(config_path).build
      else
        $stderr.puts "Usage: mildred <clean|build> [config.yml]"
        exit 1
      end
    end

    def initialize(config_path)
      @config = YAML.load_file(config_path)
      @settings = @config.fetch("settings", {})
    end

    def build
      container_dir = File.expand_path("../../container", __dir__)
      system("container", "build", "-t", IMAGE, container_dir) || abort("Build failed")
    end

    def clean
      jobs = @config.fetch("jobs", [])
      jobs.each { |job| run_job(job) }
    end

    private

    def ollama_api_base
      ollama = @settings.dig("ollama") || {}
      host = ollama.fetch("host", "192.168.64.1")
      port = ollama.fetch("port", 11434)
      "http://#{host}:#{port}/v1"
    end

    def model
      @settings.fetch("model", "granite4:latest")
    end

    def run_job(job)
      name = job.fetch("name")
      directory = File.expand_path(job.fetch("directory"))
      tasks = job.fetch("tasks", [])

      puts "Spinning up container..."
      puts

      cmd = [
        "container", "run", "-i", "--rm",
        "--volume", "#{directory}:/workspace",
        "-e", "OLLAMA_API_BASE=#{ollama_api_base}",
        "-e", "MILDRED_MODEL=#{model}",
        IMAGE
      ]

      Open3.popen3(*cmd) do |stdin, stdout, stderr, wait_thread|
        stderr_reader = Thread.new do
          stderr.each_line do |line|
            if line.include?("Calling tool:")
              puts "  #{line.strip}"
            elsif line.include?("Arguments:")
              puts "    #{line.strip}"
            end
          end
        end

        tasks.each do |task|
          stdin.puts task
          stdin.flush
        end
        stdin.close

        stdout.each_line { |line| puts "  #{line}" }
        stderr_reader.join
        wait_thread.value
      end

      puts
      puts "Finished!"
    end
  end
end
