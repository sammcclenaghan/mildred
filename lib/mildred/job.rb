# frozen_string_literal: true

require "yaml"

module Mildred
  class Job
    class ParseError < StandardError; end

    attr_reader :name, :directory, :destinations, :tasks

    def self.from_yaml(path)
      data = YAML.safe_load_file(path) || {}

      raise ParseError, "Missing 'jobs' key" unless data.is_a?(Hash) && data.key?("jobs")

      data["jobs"].map { |entry| parse_job(entry) }
    end

    def self.parse_job(entry)
      raise ParseError, "Job is missing 'name'" unless entry["name"]
      raise ParseError, "Job is missing 'directory'" unless entry["directory"]
      raise ParseError, "Job is missing 'tasks'" unless entry["tasks"]
      raise ParseError, "Job 'tasks' cannot be empty" if entry["tasks"].empty?

      new(
        name: entry["name"],
        directory: File.expand_path(entry["directory"]),
        destinations: (entry["destinations"] || []).map { |d| File.expand_path(d) },
        tasks: entry["tasks"]
      )
    end
    private_class_method :parse_job

    private

    def initialize(name:, directory:, destinations:, tasks:)
      @name = name
      @directory = directory
      @destinations = destinations
      @tasks = tasks
    end
  end
end
