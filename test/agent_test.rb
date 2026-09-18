require_relative "test_helper"

# Replays a real Ollama conversation recorded into test/cassettes/agent_moves_documents.yml.
# The LLM responses come from the cassette; the tool calls run for real against a tmpdir.
class AgentTest < Minitest::Test
  FILES = {
    "downloads/report.pdf" => "",
    "downloads/slides.pptx" => "",
    "downloads/photo.jpg" => "",
    "downloads/song.mp3" => ""
  }.freeze

  def test_moves_documents_and_leaves_the_rest
    Dir.mktmpdir("mildred") do |dir|
      FILES.each_key do |path|
        FileUtils.mkdir_p(File.dirname(File.join(dir, path)))
        File.write(File.join(dir, path), "")
      end
      FileUtils.mkdir_p(File.join(dir, "documents"))
      out = StringIO.new

      VCR.use_cassette("agent_moves_documents") do
        Agent.new(workspace: dir, model: TEST_MODEL, out: out).run(["Move any documents or presentations from downloads to documents"])
      end

      assert File.exist?(File.join(dir, "documents/report.pdf"))
      assert File.exist?(File.join(dir, "documents/slides.pptx"))
      assert File.exist?(File.join(dir, "downloads/photo.jpg"))
      assert File.exist?(File.join(dir, "downloads/song.mp3"))

      assert_match(/→ list_files downloads/, out.string)
      assert_equal 2, out.string.scan(/→ move_file/).length
      refute_match(/no summary from model|Error:/, out.string)
    end
  end
end
