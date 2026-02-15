# frozen_string_literal: true

require "fileutils"

module Mildred
  class Logger
    LOG_DIR = File.join(Dir.home, ".mildred")
    LOG_PATH = File.join(LOG_DIR, "mildred.log")

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

      fields = { event: "exec", command: command, exit_code: exit_code }
      fields[:stdout] = truncate(stdout) unless stdout.empty?
      fields[:stderr] = truncate(stderr) unless stderr.empty?
      write(**fields)
    end

    def log_job_start(job_name)
      write(event: "started", job: job_name)
    end

    def log_job_end(job_name, success:, error: nil)
      status = success ? "success" : "error"
      fields = { event: "completed", job: job_name, status: status }
      fields[:error] = error if error
      write(**fields)
    end

    def clear
      @entries = []
    end

    private

    def write(**fields)
      FileUtils.mkdir_p(LOG_DIR)

      job = fields.delete(:job) || Mildred::Current.job_name
      timestamp = Time.now.iso8601

      parts = ["[#{timestamp}]"]
      parts << "job=#{quote(job)}" if job
      fields.each { |k, v| parts << "#{k}=#{quote(v)}" }

      File.open(LOG_PATH, "a") { |f| f.puts(parts.join(" ")) }
    end

    def truncate(value, max: 200)
      value = value.to_s.strip.gsub("\n", "\\n")
      value.length > max ? "#{value[0, max]}..." : value
    end

    def quote(value)
      value = value.to_s
      value.include?(" ") ? "\"#{value}\"" : value
    end
  end
end
