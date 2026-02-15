# frozen_string_literal: true

require "open3"
require "securerandom"

module Mildred
  class Container
    class Error < StandardError; end

    IMAGE = "mildred-sandbox:latest"

    CONTAINERFILE = <<~DOCKERFILE
      FROM alpine:3.20
      RUN apk add --no-cache bash coreutils findutils
    DOCKERFILE

    attr_reader :id

    def initialize(job:)
      @job = job
      @id = nil
    end

    def start
      ensure_mount_paths_exist
      @id = run_container
    end

    def stop
      return unless @id

      run_cli("container", "stop", @id)
      run_cli("container", "rm", @id)
      @id = nil
    end

    def self.ensure_image
      return if image_exists?

      build_image
    end

    def self.cleanup_stale
      ids = stale_container_ids
      return if ids.empty?

      ids.each do |id|
        Open3.capture3("container", "stop", id)
        Open3.capture3("container", "rm", id)
      end
    end

    class << self
      private

      def image_exists?
        stdout, _, status = Open3.capture3("container", "image", "list", "--format", "json")
        return false unless status.success?

        images = JSON.parse(stdout)
        images.any? { |img| img["reference"]&.end_with?(IMAGE) }
      end

      def build_image
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "Containerfile"), CONTAINERFILE)

          _stdout, stderr, status = Open3.capture3(
            "container", "build", "-t", IMAGE, dir
          )
          raise Error, "Failed to build image: #{stderr}" unless status.success?
        end
      end

      def stale_container_ids
        stdout, _, status = Open3.capture3("container", "ls", "-a", "--quiet")
        return [] unless status.success?

        stdout.lines.map(&:strip).select { |id| id.start_with?("mildred-") }
      end
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
      args.concat([IMAGE, "sleep", "infinity"])

      _stdout, stderr, status = Open3.capture3(*args)
      raise Error, "Failed to start container: #{stderr}" unless status.success?

      name
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
