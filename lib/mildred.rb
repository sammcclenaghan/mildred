# frozen_string_literal: true

require "ruby_llm"

require_relative "mildred/version"
require_relative "mildred/configuration"
require_relative "mildred/tools/list_files"
require_relative "mildred/tools/file_metadata"
require_relative "mildred/tools/move_file"
require_relative "mildred/agent"

module Mildred
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure!
      @configuration = Configuration.new
      configuration.apply!
    end
  end
end
