# frozen_string_literal: true

require "fileutils"

module Mildred
  module Tools
    class MoveFile < RubyLLM::Tool
      description "Moves or renames a file or directory"

      param :source, desc: "The current path of the file or directory"
      param :destination, desc: "The target path to move or rename to"

      def execute(source:, destination:)
        return { error: "Source does not exist: #{source}" } unless File.exist?(source)
        return { error: "Destination already exists: #{destination}" } if File.exist?(destination)

        dest_dir = File.dirname(destination)
        FileUtils.mkdir_p(dest_dir) unless Dir.exist?(dest_dir)

        FileUtils.mv(source, destination)

        { moved: source, to: destination }
      end
    end
  end
end
