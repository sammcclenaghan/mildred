# frozen_string_literal: true

require "open3"
require "securerandom"

module Mildred
  class Container
    class Error < StandardError; end

    DEFAULT_IMAGE = "alpine:3.20"

    attr_reader :id

    def initialize(job:, image: DEFAULT_IMAGE)
      @job = job
      @image = image
      @id = nil
    end

    def start
      ensure_mount_paths_exist
      @id = run_container
      install_packages
      @id
    end

    def stop
      return unless @id

      run_cli("container", "stop", @id)
      run_cli("container", "rm", @id)
      @id = nil
    end

    private

    def ensure_mount_paths_exist
      paths = ([@job.directory] + @job.destinations).uniq
      paths.each { |path| FileUtils.mkdir_p(path) }
    end

    def run_container
      name = "mildred-#{Process.pid}-#{SecureRandom.hex(4)}"

      args = ["container", "run", "-d", "--name", name]
      args.concat(mount_args)
      args.concat([@image, "sh", "-c", "sleep infinity"])

      _stdout, stderr, status = Open3.capture3(*args)
      raise Error, "Failed to start container: #{stderr}" unless status.success?

      name
    end

    def install_packages
      _stdout, stderr, status = Open3.capture3(
        "container", "exec", @id, "sh", "-c",
        "apk add --no-cache bash coreutils findutils"
      )
      raise Error, "Failed to install packages: #{stderr}" unless status.success?
    end

    def mount_args
      paths = ([@job.directory] + @job.destinations).uniq
      paths.flat_map { |path| ["-v", "#{path}:#{path}"] }
    end

    def run_cli(*args)
      Open3.capture3(*args)
    end
  end
end
