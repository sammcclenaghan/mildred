require "ruby_llm/tool"
require "fileutils"

module Tools
  class CreateDirectory < RubyLLM::Tool
    description "Create a new directory at the given path. Creates parent directories if needed."
    param :path, desc: "The relative path of the directory to create."

    def execute(path:)
      FileUtils.mkdir_p(path)
      "Created directory: #{path}"
    rescue => e
      { error: e.message }
    end
  end
end
