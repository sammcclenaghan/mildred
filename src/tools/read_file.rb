require "ruby_llm/tool"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class ReadFile < RubyLLM::Tool
    include Loggable
    include DryRunnable
    description "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names."
    param :path, desc: "The relative path of a file in the working directory."

    def execute(path:)
      info "Reading file at path: #{path}"
      File.read(path)
    rescue => e
      { error: e.message }
    end
  end
end
