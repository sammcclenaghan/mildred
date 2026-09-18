$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "stringio"
require "webmock/minitest"
require "vcr"

require "mildred"
require_relative "../container/agent"

# The agent test replays a recorded Ollama conversation from test/cassettes.
# To re-record, delete the cassette and run the tests with Ollama running locally.
OLLAMA_API_BASE = ENV.fetch("OLLAMA_API_BASE", "http://127.0.0.1:11434/v1")
TEST_MODEL      = ENV.fetch("MILDRED_MODEL", "gemma4:e2b")

RubyLLM.configure do |c|
  c.openai_api_base = OLLAMA_API_BASE
  c.openai_api_key = "ollama"
  c.openai_use_system_role = true
end

VCR.configure do |c|
  c.cassette_library_dir = File.expand_path("cassettes", __dir__)
  c.hook_into :webmock
  c.default_cassette_options = { record: :once, match_requests_on: %i[method uri] }
end

module WorkspaceHelper
  # Builds a throwaway workspace with a downloads/ and documents/ folder and
  # yields with the current directory set to it, the way the agent sees it.
  def with_workspace(files = {})
    Dir.mktmpdir("mildred") do |dir|
      FileUtils.mkdir_p(File.join(dir, "downloads"))
      FileUtils.mkdir_p(File.join(dir, "documents"))
      files.each do |path, content|
        FileUtils.mkdir_p(File.dirname(File.join(dir, path)))
        File.write(File.join(dir, path), content)
      end
      Dir.chdir(dir) { yield dir }
    end
  end
end
