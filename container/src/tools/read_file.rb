require "ruby_llm/tool"

module Tools
  class ReadFile < RubyLLM::Tool
    description "Read the contents of a give relative file path. Use this when you want to see what's inside a file. Do not use this with directory names."

    def name
      "read_file"
    end
    param :path, desc: "The relative path of a file in the working directory."

    def execute(path:)
      File.read(path)
    rescue => e
      { error: e.message }
    end
  end
end
