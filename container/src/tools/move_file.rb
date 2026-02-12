require "ruby_llm/tool"
require "fileutils"

module Tools
  class MoveFile < RubyLLM::Tool
    description "Move or rename a file or directory from one path to another."
    param :source, desc: "The relative path of the file or directory to move."
    param :destination, desc: "The relative path to move the file or directory to."

    def execute(source:, destination:)
      if ENV["MILDRED_DRY_RUN"] == "1"
        return "[DRY RUN] Would move #{source} to #{destination}"
      end

      FileUtils.mv(source, destination)
      "Moved #{source} to #{destination}"
    rescue => e
      { error: e.message }
    end
  end
end
