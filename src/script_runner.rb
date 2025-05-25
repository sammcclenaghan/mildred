require_relative 'agent'
require 'logger'

class ScriptRunner
  attr_reader :agent, :logger

  def initialize(dry_run: false)
    @agent = Agent.new(dry_run: dry_run, root_path: Dir.pwd)
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def run_script(script_path)
    absolute_path = File.expand_path(script_path)
    unless File.exist?(absolute_path)
      logger.error "Script file not found: #{absolute_path}"
      return false
    end

    script_dir = File.dirname(absolute_path)
    logger.info "Running script: #{absolute_path} from directory: #{script_dir}"
    
    Dir.chdir(script_dir) do
      File.readlines(absolute_path).each_with_index do |line, index|
        line = line.strip
        next if line.empty? || line.start_with?('#')

        logger.info "Executing line #{index + 1}: #{line}"
        begin
          response = agent.ask(line)
          logger.info "Response: #{response.content}"
        rescue => e
          logger.error "Error executing line #{index + 1}: #{e.message}"
          return false
        end
      end
    end

    true
  rescue => e
    logger.error "Script execution failed: #{e.message}"
    false
  end

  def self.run(script_path, dry_run: false)
    new(dry_run: dry_run).run_script(script_path)
  end
end