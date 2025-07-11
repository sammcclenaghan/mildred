require "ruby_llm/tool"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class ReadFile < RubyLLM::Tool
    include Loggable
    include DryRunnable
    description "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names."
    param :path, desc: "The relative path of a file in the working directory."

    def initialize(navigation_tool: nil)
      super()
      @navigation_tool = navigation_tool
    end

    def execute(path:)
      # Use navigation tool's current path if available, otherwise use process working directory
      base_path = @navigation_tool&.current_path || Dir.pwd
      full_path = File.expand_path(path, base_path)

      info "Reading file at path: #{full_path}"
      File.read(full_path)
    rescue => e
      { error: e.message }
    end
  end
end
