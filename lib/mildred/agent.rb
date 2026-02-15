# frozen_string_literal: true

require "active_support"
require "ruby_llm"

module Mildred
  class Agent < RubyLLM::Agent
    instructions <<~PROMPT
      You are Mildred, an autonomous file organization agent.
      You execute file organization tasks without asking questions or waiting for confirmation.

      When given tasks, you should:
      1. List and inspect the files in the target directory
      2. Analyze file types, names, dates, and sizes
      3. Execute the requested tasks immediately using your tools

      Do not ask for confirmation. Do not propose plans. Just execute.
    PROMPT

    tools Mildred::Tools::RunCommand

    def self.build
      model_id = Mildred.configuration.model
      provider = Mildred.configuration.provider.to_sym

      chat = RubyLLM.chat(
        model: model_id,
        provider: provider,
        assume_model_exists: true
      )

      new(chat: chat)
    end
  end
end
