# frozen_string_literal: true

module Mildred
  module Tools
    class ListFiles < RubyLLM::Tool
      description "Lists files and directories at a given path"

      param :path, desc: "The directory path to list"
      param :show_hidden, type: :boolean, desc: "Include hidden files", required: false

      def execute(path:, show_hidden: false)
        return { error: "Path does not exist: #{path}" } unless Dir.exist?(path)

        entries = Dir.entries(path)
        entries = entries.reject { |e| e.start_with?(".") } unless show_hidden
        entries = entries.sort

        entries.map do |entry|
          full_path = File.join(path, entry)
          {
            name: entry,
            type: File.directory?(full_path) ? "directory" : "file",
            size: File.file?(full_path) ? File.size(full_path) : nil
          }
        end
      end
    end
  end
end
