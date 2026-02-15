# frozen_string_literal: true

require "gum"

module Mildred
  class Runner
    DEFAULT_RULES_PATH = File.join(".mildred", "rules.yml")

    attr_reader :jobs

    def initialize(path: DEFAULT_RULES_PATH)
      @jobs = Job.from_yaml(path)
    end

    def run
      Container.cleanup_stale
      Container.ensure_image

      @jobs.each do |job|
        puts Gum.style(
          "▸ #{job.name}",
          foreground: "212",
          bold: true
        )

        result = Gum.spin("Running #{job.name}...", spinner: :dot) do
          execute_job(job)
        end

        if result
          puts Gum.style("  ✓ Done", foreground: "46")
        else
          puts Gum.style("  ✗ Failed", foreground: "196")
        end
      end
    end

    private

    def execute_job(job)
      container = Container.new(job: job)
      container.start

      Mildred::Current.container_id = container.id

      agent = Agent.build
      prompt = build_prompt(job)
      agent.ask(prompt)
      true
    rescue StandardError
      false
    ensure
      Mildred::Current.reset
      container&.stop
    end

    def build_prompt(job)
      lines = []
      lines << "You are organizing the directory: #{job.directory}"

      unless job.destinations.empty?
        lines << "Available destinations: #{job.destinations.join(', ')}"
      end

      lines << ""
      lines << "Complete the following tasks:"
      job.tasks.each_with_index do |task, i|
        lines << "#{i + 1}. #{task}"
      end

      lines << ""
      lines << "Do not ask questions. Execute each task using your tools."

      lines.join("\n")
    end
  end
end
