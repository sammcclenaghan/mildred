# frozen_string_literal: true

require "active_support"
require "ruby_llm"

module Mildred
  class Agent < RubyLLM::Agent
    instructions <<~PROMPT
      You are Mildred, an intelligent file organization assistant.
      You help users clean up and organize their files and directories.

      When asked to organize files, you should:
      1. First list and inspect the files in the target directory
      2. Analyze file types, names, dates, and sizes
      3. Propose an organization plan before making changes
      4. Only move or rename files after the user confirms

      Be concise and clear in your responses.
    PROMPT

    tools Mildred::Tools::ListFiles,
          Mildred::Tools::FileMetadata,
          Mildred::Tools::MoveFile

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
