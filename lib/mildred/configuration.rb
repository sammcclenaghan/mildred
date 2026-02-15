# frozen_string_literal: true

require "yaml"

module Mildred
  class Configuration
    DEFAULTS = {
      "provider" => "ollama",
      "model" => "llama3.2",
      "ollama_url" => "http://localhost:11434/v1"
    }.freeze

    CONFIG_DIR = File.join(Dir.home, ".config", "mildred")
    CONFIG_PATH = File.join(CONFIG_DIR, "config.yml")

    attr_reader :provider, :model, :settings

    def initialize
      @settings = load_config
      @provider = @settings["provider"]
      @model = @settings["model"]
    end

    def apply!
      config_data = @settings

      RubyLLM.configure do |config|
        case @provider
        when "ollama"
          config.ollama_api_base = config_data["ollama_url"]
        when "openai"
          config.openai_api_key = config_data["openai_api_key"]
        when "openrouter"
          config.openrouter_api_key = config_data["openrouter_api_key"]
        end

        config.default_model = @model
      end
    end

    private

    def load_config
      if File.exist?(CONFIG_PATH)
        DEFAULTS.merge(YAML.safe_load_file(CONFIG_PATH) || {})
      else
        DEFAULTS.dup
      end
    end
  end
end
