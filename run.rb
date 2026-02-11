require "ruby_llm"
require_relative "src/agent"

RubyLLM.configure do |config|
  config.openai_use_system_role = true
  config.openai_api_base = "http://localhost:11434/v1"
  config.openai_api_key = "dummy-key"
end

Agent.new.run
