require "open3"

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
        display_success("Image built")
        puts
      end

      private

      def check_container_cli!
        _, status = Open3.capture2("which", "container")
        return if status.success?

        raise Error, "Apple Container CLI not found. Install from https://github.com/apple/container"
      end
    end
  end
end
