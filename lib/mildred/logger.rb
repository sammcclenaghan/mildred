# frozen_string_literal: true

module Mildred
  class Logger
    attr_reader :entries

    def initialize
      @entries = []
    end

    def log(command, stdout, stderr, exit_code)
      @entries << {
        command: command,
        stdout: stdout,
        stderr: stderr,
        exit_code: exit_code
      }
    end

    def clear
      @entries = []
    end
  end
end
