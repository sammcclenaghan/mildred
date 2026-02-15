# frozen_string_literal: true

require "open3"

module Mildred
  module Tools
    class RunCommand < RubyLLM::Tool
      description "Executes a shell command and returns its output. Use this to organize, move, delete, and inspect files."

      param :command, desc: "The shell command to execute"

      def execute(command:)
        stdout, stderr, status = Open3.capture3("bash", "-c", command)

        Mildred.logger.log(command, stdout, stderr, status.exitstatus)

        {
          stdout: stdout,
          stderr: stderr,
          exit_code: status.exitstatus
        }
      end
    end
  end
end
