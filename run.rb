require 'ruby_llm'
require 'dotenv/load'
require_relative 'src/agent'
require_relative 'src/script_runner'

RubyLLM.configure do |config|
  config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)
  config.default_model = 'deepseek-chat'
end

current_dir = Dir.pwd
dry_run = ARGV.include?("--dry-run")
script_path = ARGV.find { |arg| !arg.start_with?('--') }

if script_path
  absolute_script_path = File.expand_path(script_path, current_dir)
  Dir.chdir(ENV['HOME']) do
    Dir.chdir(ENV['HOME']) do
      ScriptRunner.run(absolute_script_path, dry_run: dry_run)
    end
  end
else
  Dir.chdir(ENV['HOME']) do
    agent = Agent.new(dry_run: dry_run, root_path: ENV['HOME'])
    agent.run
  end
end
