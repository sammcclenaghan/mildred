# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def test_defaults_to_ollama
    config = Mildred::Configuration.new

    assert_equal "ollama", config.provider
    assert_equal "llama3.1:8b", config.model
  end

  def test_loads_from_yaml
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, "config.yml")
      File.write(config_path, <<~YAML)
        provider: openrouter
        model: anthropic/claude-sonnet-4
        openrouter_api_key: sk-or-test
      YAML

      # Temporarily override CONFIG_PATH
      original = Mildred::Configuration::CONFIG_PATH
      Mildred::Configuration.send(:remove_const, :CONFIG_PATH)
      Mildred::Configuration.const_set(:CONFIG_PATH, config_path)

      config = Mildred::Configuration.new

      assert_equal "openrouter", config.provider
      assert_equal "anthropic/claude-sonnet-4", config.model
    ensure
      Mildred::Configuration.send(:remove_const, :CONFIG_PATH)
      Mildred::Configuration.const_set(:CONFIG_PATH, original)
    end
  end

  def test_merges_defaults_with_partial_yaml
    Dir.mktmpdir do |dir|
      config_path = File.join(dir, "config.yml")
      File.write(config_path, <<~YAML)
        model: mistral
      YAML

      original = Mildred::Configuration::CONFIG_PATH
      Mildred::Configuration.send(:remove_const, :CONFIG_PATH)
      Mildred::Configuration.const_set(:CONFIG_PATH, config_path)

      config = Mildred::Configuration.new

      assert_equal "ollama", config.provider # default kept
      assert_equal "mistral", config.model   # overridden
    ensure
      Mildred::Configuration.send(:remove_const, :CONFIG_PATH)
      Mildred::Configuration.const_set(:CONFIG_PATH, original)
    end
  end
end
