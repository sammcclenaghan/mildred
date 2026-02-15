# frozen_string_literal: true

require "test_helper"

class TestAgent < Minitest::Test
  FIXTURE_DIR = File.expand_path("fixtures/sample_dir", __dir__)

  def setup
    FileUtils.rm_rf(FIXTURE_DIR)
    FileUtils.mkdir_p(FIXTURE_DIR)

    File.write(File.join(FIXTURE_DIR, "photo.jpg"), "fake image data")
    File.write(File.join(FIXTURE_DIR, "document.pdf"), "fake pdf data")
    File.write(File.join(FIXTURE_DIR, "notes.txt"), "some notes")
  end

  def teardown
    FileUtils.rm_rf(FIXTURE_DIR)
    FileUtils.mkdir_p(FIXTURE_DIR)
  end

  def test_agent_lists_files
    VCR.use_cassette("agent_list_files") do
      agent = Mildred::Agent.build
      response = agent.ask("List all the files in #{FIXTURE_DIR}")

      content = response.content.downcase
      assert_includes content, "photo.jpg"
      assert_includes content, "document.pdf"
      assert_includes content, "notes.txt"
    end
  end

  def test_agent_inspects_file_metadata
    VCR.use_cassette("agent_file_metadata") do
      agent = Mildred::Agent.build
      response = agent.ask("Tell me the size and type of #{File.join(FIXTURE_DIR, 'photo.jpg')}")

      content = response.content.downcase
      assert_includes content, "photo"
      assert(content.include?("jpg") || content.include?("image") || content.include?("file"),
             "Expected response to mention file type")
      assert(content.match?(/\d+/), "Expected response to mention file size")
    end
  end

  def test_agent_moves_file
    source = File.join(FIXTURE_DIR, "notes.txt")
    dest = File.join(FIXTURE_DIR, "archive", "notes.txt")

    VCR.use_cassette("agent_move_file") do
      agent = Mildred::Agent.build
      agent.ask("Move #{source} to #{dest}")
    end

    refute File.exist?(source), "Source file should no longer exist"
    assert File.exist?(dest), "File should have been moved to destination"
    assert_equal "some notes", File.read(dest)
  end
end
