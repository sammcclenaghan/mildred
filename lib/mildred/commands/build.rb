require "open3"

module Mildred
  module Commands
    class Build < Command
      desc "Build the container image"

      def call
        check_container_cli!
        container_dir = File.expand_path("../../../container", __dir__)

        display_header("Build")
        Gum.spin("Building mildred image...", spinner: :dot) do
          system("container", "build", "-t", "mildred", "-q", container_dir, out: File::NULL, err: File::NULL)
        end
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
