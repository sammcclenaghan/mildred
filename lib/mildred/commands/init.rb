module Mildred
  module Commands
    class Init < Command
      desc "Generate a starter mildred.yml"

      TEMPLATE = <<~YAML
        # Mildred Configuration
        # https://github.com/sammcclenaghan/mildred

        settings:
          provider: ollama
          model: qwen3:8b

          ollama:
            port: 11434

        jobs:
          - name: Desktop Cleanup
            directory: ~/Desktop
            tasks:
              - Organize files into folders by type (Documents, Images, Archives)
      YAML

      def call
        path = @args[0] || "mildred.yml"

        if File.exist?(path)
          raise Error, "#{path} already exists"
        end

        display_header("Init")
        File.write(path, TEMPLATE)
        display_success("Created #{path}")
        display_info("Edit the file, then run: mildred clean")
        puts
      end
    end
  end
end
