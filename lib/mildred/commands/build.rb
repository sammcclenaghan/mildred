require "open3"
require "digest"

module Mildred
  module Commands
    class Build < Command
      desc "Build the container image"

      def call
        check_container_cli!
        container_dir = File.expand_path("../../../container", __dir__)

        display_header("Build")
        output, status = nil
        Gum.spin("Building mildred image...", spinner: :dot) do
          output, status = Open3.capture2e("container", "build", "-t", "mildred", container_dir)
        end
        raise Error, "Build failed:\n#{output.lines.last(5).join}" unless status&.success?

        write_build_digest(container_dir)
        display_success("Image built")
        puts
      end

      private

      def check_container_cli!
        _, status = Open3.capture2("which", "container")
        return if status.success?

        raise Error, "Apple Container CLI not found. Install from https://github.com/apple/container"
      end

      def write_build_digest(container_dir)
        files = Dir.glob(File.join(container_dir, "**/*"))
          .select { |f| File.file?(f) && !f.end_with?(".build-digest") }
          .sort
        content = files.map { |f| "#{f}:#{File.read(f)}" }.join
        digest = Digest::SHA256.hexdigest(content)[0, 12]
        File.write(File.join(container_dir, ".build-digest"), digest)
      end
    end
  end
end
