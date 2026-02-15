# frozen_string_literal: true

require "gum"

module Mildred
  class Runner
    DEFAULT_RULES_PATH = File.join(Dir.home, ".mildred", "rules.yml")

    attr_reader :jobs, :noop

    def initialize(path: DEFAULT_RULES_PATH, noop: false)
      @jobs = Job.from_yaml(path)
      @noop = noop
    end

    def run
      if @noop
        puts Gum.style("▸ Dry run — no changes will be made", foreground: "220", bold: true)
        puts
      else
        Gum.spin("Cleaning up stale containers...", spinner: :dot) { Container.cleanup_stale }
        Gum.spin("Ensuring sandbox image...", spinner: :dot) { Container.ensure_image }
        puts
      end

      results = @jobs.map do |job|
        puts Gum.style("▸ #{job.name}", foreground: "212", bold: true)

        result = Gum.spin("Running #{job.name}...", spinner: :dot) do
          execute_job(job)
        end

        if result == true
          puts Gum.style("  ✓ Done", foreground: "46")
        else
          puts Gum.style("  ✗ Failed", foreground: "196")
          puts Gum.style("    #{result.message}", foreground: "196", faint: true) if result.is_a?(StandardError)
        end

        result == true
      end

      passed = results.count { |r| r }
      total = results.length
      puts
      if passed == total
        puts Gum.style("✓ #{passed}/#{total} jobs completed", foreground: "46", bold: true)
      else
        puts Gum.style("⚠ #{passed}/#{total} jobs completed", foreground: "220", bold: true)
      end
    end

    private

    MAX_RETRIES = 2

    def execute_job(job)
      Mildred::Current.job_name = job.name
      Mildred.logger.log_job_start(job.name)

      if @noop
        Mildred::Current.noop = true
      else
        container = Container.new(job: job)
        container.start
        Mildred::Current.container_id = container.id
      end

      run_agent(job)

      Mildred.logger.log_job_end(job.name, success: true)
      true
    rescue StandardError => e
      Mildred.logger.log_job_end(job.name, success: false, error: e.message)
      e
    ensure
      Mildred::Current.reset
      container&.stop unless @noop
    end

    def run_agent(job, attempt: 1)
      agent = Agent.build
      prompt = build_prompt(job)
      agent.ask(prompt)
    rescue StandardError => e
      raise unless attempt < MAX_RETRIES

      Mildred.logger.log(
        "retry", "[attempt #{attempt} failed: #{e.message}]", "", 0
      )
      run_agent(job, attempt: attempt + 1)
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
