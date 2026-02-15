# frozen_string_literal: true

unless RUBY_PLATFORM.match?(/darwin/)
  raise "Mildred requires macOS (Apple containers). See https://github.com/sammcclenaghan/mildred"
end

require "ruby_llm"

require_relative "mildred/version"
require_relative "mildred/configuration"
require_relative "mildred/current"
require_relative "mildred/logger"
require_relative "mildred/job"
require_relative "mildred/container"
require_relative "mildred/tools/run_command"
require_relative "mildred/agent"
require_relative "mildred/runner"

module Mildred
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure!
      @configuration = Configuration.new
      configuration.apply!
    end

    def logger
      @logger ||= Logger.new
    end
  end
end
