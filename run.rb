require 'ruby_llm'
require_relative 'src/agent'

RubyLLM.configure do |config|
  config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)

  config.default_model = 'deepseek-chat'
  Agent.new.run
end
