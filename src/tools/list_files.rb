require "ruby_llm/tool"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class ListFiles < RubyLLM::Tool
    include Loggable
    include DryRunnable
    description "List files and directories at a given path. If no path is provided, lists files in the current directory."
    param :path, desc: "Optional relative path to list files from. Defaults to current directory if not provided."

    def execute(path: "")
      info "Listing files at path: #{path}"
      Dir.glob(File.join(path, "*"))
         .map { |filename| File.directory?(filename) ? "#{filename}/" : filename }
    rescue => e
      { error: e.message }
    end
  end
end
