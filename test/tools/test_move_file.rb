# frozen_string_literal: true

require "test_helper"

class TestMoveFile < Minitest::Test
  def setup
    @tool = Mildred::Tools::MoveFile.new
    @dir = Dir.mktmpdir("mildred-test")
    @source = File.join(@dir, "original.txt")
    File.write(@source, "content")
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_moves_file
    dest = File.join(@dir, "moved.txt")
    result = @tool.execute(source: @source, destination: dest)

    assert_equal @source, result[:moved]
    assert_equal dest, result[:to]
    refute File.exist?(@source)
    assert File.exist?(dest)
    assert_equal "content", File.read(dest)
  end

  def test_creates_destination_directory
    dest = File.join(@dir, "new_dir", "moved.txt")
    @tool.execute(source: @source, destination: dest)

    assert File.exist?(dest)
  end

  def test_returns_error_when_source_missing
    result = @tool.execute(source: "/nonexistent", destination: File.join(@dir, "dest.txt"))

    assert_match(/does not exist/, result[:error])
  end

  def test_returns_error_when_destination_exists
    dest = File.join(@dir, "existing.txt")
    File.write(dest, "taken")

    result = @tool.execute(source: @source, destination: dest)

    assert_match(/already exists/, result[:error])
    assert File.exist?(@source) # source untouched
  end
end
