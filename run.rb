require 'ruby_llm'
require 'dotenv/load'
require_relative 'src/agent'

RubyLLM.configure do |config|
  config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)
  config.default_model = 'deepseek-chat'

  dry_run = ARGV.include?("--dry-run")
  agent = Agent.new(dry_run: dry_run)
  agent.run
end
