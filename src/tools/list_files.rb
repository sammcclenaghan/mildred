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

    def execute(path: "")
      info "Listing files at path: #{path}"
      Dir.glob(File.join(path, "*"))
         .map { |filename| File.directory?(filename) ? "#{filename}/" : filename }
    rescue => e
      { error: e.message }
    end
  end
end
