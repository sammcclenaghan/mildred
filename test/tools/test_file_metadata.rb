# frozen_string_literal: true

require "test_helper"

class TestFileMetadata < Minitest::Test
  def setup
    @tool = Mildred::Tools::FileMetadata.new
    @dir = Dir.mktmpdir("mildred-test")
    @file = File.join(@dir, "sample.txt")
    File.write(@file, "hello world")
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_returns_file_metadata
    result = @tool.execute(path: @file)

    assert_equal "sample.txt", result[:name]
    assert_equal ".txt", result[:extension]
    assert_equal "file", result[:type]
    assert_equal 11, result[:size_bytes]
  end

  def test_returns_directory_metadata
    result = @tool.execute(path: @dir)

    assert_equal "directory", result[:type]
  end

  def test_includes_timestamps
    result = @tool.execute(path: @file)

    refute_nil result[:created_at]
    refute_nil result[:modified_at]
  end

  def test_returns_error_for_nonexistent_path
    result = @tool.execute(path: "/nonexistent/file.txt")

    assert_match(/does not exist/, result[:error])
  end
end
