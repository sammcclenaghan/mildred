# frozen_string_literal: true

module Mildred
  module Tools
    class FileMetadata < RubyLLM::Tool
      description "Gets detailed metadata for a file or directory"

      param :path, desc: "The file or directory path to inspect"

      def execute(path:)
        return { error: "Path does not exist: #{path}" } unless File.exist?(path)

        stat = File.stat(path)

        {
          name: File.basename(path),
          extension: File.extname(path),
          type: stat.directory? ? "directory" : "file",
          size_bytes: stat.size,
          created_at: stat.birthtime.iso8601,
          modified_at: stat.mtime.iso8601,
          permissions: stat.mode.to_s(8)
        }
      end
    end
  end
end
