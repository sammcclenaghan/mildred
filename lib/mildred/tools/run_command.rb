# frozen_string_literal: true

require "open3"

module Mildred
  module Tools
    class RunCommand < RubyLLM::Tool
      description "Executes a shell command and returns its output. Use this to organize, move, delete, and inspect files."

      param :command, desc: "The shell command to execute"

      def execute(command:)
        container_id = Mildred::Current.container_id

        stdout, stderr, status = if container_id
          Open3.capture3("container", "exec", container_id, "bash", "-c", command)
        else
          Open3.capture3("bash", "-c", command)
        end

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
