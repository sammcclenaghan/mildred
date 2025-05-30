require "ruby_llm/tool"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class ListFiles < RubyLLM::Tool
    include Loggable
    include DryRunnable
    description "List files and directories at a given path with advanced options"
    param :path, desc: "Optional relative path to list files from. Defaults to current directory if not provided."
    param :recursive, desc: "Whether to list files recursively", required: false
    param :pattern, desc: "Optional glob pattern to filter files (e.g., '**/*.rb')", required: false

    def execute(path: ".", recursive: false, pattern: "*")
      # Resolve the path relative to current directory
      full_path = File.expand_path(path)
      info "Listing files at path: #{full_path} (recursive: #{recursive})"

      search_pattern = if recursive
        File.join(full_path, "**", pattern)
      else
        File.join(full_path, pattern)
      end

      files = Dir.glob(search_pattern).map do |filename|
        {
          path: filename,
          type: File.directory?(filename) ? "directory" : "file",
          size: File.size(filename),
          modified: File.mtime(filename).iso8601,
          permissions: File.stat(filename).mode.to_s(8)
        }
      end

      {
        current_directory: full_path,
        files: files,
        total_count: files.length
      }
    rescue => e
      { error: e.message }
    end
  end
end
