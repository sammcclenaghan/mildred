require "yaml"
require "net/http"
require "optparse"

module Mildred
  IMAGE = "mildred"
  CONTAINER_DIR = File.expand_path("../container", __dir__)
  Error = Class.new(StandardError)

  USAGE = <<~TEXT
    usage: mildred <command>

      init [path]        write a starter mildred.yml
      clean              run the jobs in mildred.yml
        -n, --dry-run      preview without moving anything
        -c, --config PATH  use a different config file
        -j, --job NAME     run only the job with this name
      build              build the container image
  TEXT

  TEMPLATE = <<~YAML
    settings:
      model: qwen2.5:7b

    jobs:
      - name: Desktop Cleanup
        directory: ~/Desktop
        tasks:
          - Organize files into folders by type (Documents, Images, Archives)

      # Move files between folders by mounting several at once:
      # - name: Sort Downloads
      #   directories:
      #     downloads: ~/Downloads
      #     documents: ~/Documents
      #   tasks:
      #     - Move PDFs and Word docs from downloads to documents
  YAML

  def self.run(argv)
    case argv.shift
    when "init"  then init(argv.first || "mildred.yml")
    when "build" then build
    when "clean" then clean(argv)
    else puts USAGE
    end
  rescue Error => e
    abort "error: #{e.message}"
  end

  def self.init(path)
    raise Error, "#{path} already exists" if File.exist?(path)

    File.write(path, TEMPLATE)
    puts "Wrote #{path}. Edit it, then run: mildred clean"
  end

  def self.build
    raise Error, "Apple Container CLI not found. Install it from https://github.com/apple/container" unless system("which container >/dev/null")

    puts "Building #{IMAGE} image..."
    system("container", "build", "-t", IMAGE, CONTAINER_DIR) or raise Error, "build failed"
  end

  def self.clean(argv)
    opts = { config: "mildred.yml", dry_run: false, job: nil }
    OptionParser.new do |o|
      o.on("-n", "--dry-run") { opts[:dry_run] = true }
      o.on("-c", "--config PATH") { |path| opts[:config] = path }
      o.on("-j", "--job NAME") { |name| opts[:job] = name }
    end.parse!(argv)

    raise Error, "#{opts[:config]} not found. Run: mildred init" unless File.exist?(opts[:config])

    config   = YAML.load_file(opts[:config])
    settings = config.fetch("settings", {})
    jobs     = config.fetch("jobs", [])
    raise Error, "no jobs defined in #{opts[:config]}" if jobs.empty?

    if opts[:job]
      jobs = jobs.select { |job| job["name"].to_s.casecmp?(opts[:job]) }
      raise Error, "no job named '#{opts[:job]}' in #{opts[:config]}" if jobs.empty?
    end

    ollama = settings.fetch("ollama", {})
    host   = ollama.fetch("host", "192.168.64.1")
    port   = ollama.fetch("port", 11434)
    model  = settings.fetch("model", "qwen2.5:7b")

    build unless image_exists?
    check_ollama!(host, port)

    jobs.each do |job|
      puts "\n== #{job["name"]}#{" (dry run)" if opts[:dry_run]}"
      run_job(job, host: host, port: port, model: model, dry_run: opts[:dry_run])
    end
  end

  def self.image_exists?
    `container image list -q`.lines.any? { |line| line.strip.start_with?(IMAGE) }
  end

  # Containers reach the host through the network gateway, not localhost,
  # so Ollama has to be listening on all interfaces.
  def self.check_ollama!(host, port)
    Net::HTTP.start(host, port, open_timeout: 3, read_timeout: 3) { |http| http.get("/") }
  rescue SystemCallError, SocketError, Net::OpenTimeout, Net::ReadTimeout
    raise Error, <<~MSG.strip
      cannot reach Ollama at #{host}:#{port}
      Make sure it is running and listening on all interfaces.
        Ollama app:  Settings → turn on "Expose Ollama to the network"
        CLI:         OLLAMA_HOST=0.0.0.0 ollama serve
    MSG
  end

  def self.directories(job)
    dirs = job["directories"] || (job["directory"] && { File.basename(job["directory"]).downcase => job["directory"] })
    raise Error, "job '#{job["name"]}' needs a 'directory' or 'directories'" unless dirs.is_a?(Hash) && !dirs.empty?

    dirs.to_h do |name, path|
      full = File.expand_path(path)
      raise Error, "directory does not exist: #{full}" unless Dir.exist?(full)
      [name.to_s, full]
    end
  end

  def self.run_job(job, **settings)
    cmd = container_command(job, **settings)
    system(*cmd) or raise Error, "container exited with status #{$?.exitstatus}"
  end

  def self.container_command(job, host:, port:, model:, dry_run:)
    tasks = Array(job["tasks"])
    raise Error, "job '#{job["name"]}' has no tasks" if tasks.empty?

    cmd = ["container", "run", "--rm"]
    directories(job).each { |name, path| cmd += ["--volume", "#{path}:/workspace/#{name}"] }
    cmd += ["-e", "OLLAMA_API_BASE=http://#{host}:#{port}/v1"]
    cmd += ["-e", "MILDRED_MODEL=#{model}"]
    cmd += ["-e", "MILDRED_DRY_RUN=#{dry_run ? 1 : 0}"]
    cmd + [IMAGE, *tasks]
  end
end
