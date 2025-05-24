# frozen_string_literal: true

require 'logger'

module Loggable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def logger
      @logger ||= begin
        logger = Logger.new($stdout)
        logger.level = ENV['LOG_LEVEL'] ? Logger.const_get(ENV['LOG_LEVEL'].upcase) : Logger::INFO
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime} [#{severity}] #{self}: #{msg}\n"
        end
        logger
      end
    end
  end

  def logger
    self.class.logger
  end

  def debug(message)
    logger.debug(message)
  end

  def info(message)
    logger.info(message)
  end

  def warn(message)
    logger.warn(message)
  end

  def error(message)
    logger.error(message)
  end

  def fatal(message)
    logger.fatal(message)
  end
end
