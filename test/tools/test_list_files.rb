# frozen_string_literal: true

require "test_helper"

class TestListFiles < Minitest::Test
  def setup
    @tool = Mildred::Tools::ListFiles.new
    @dir = Dir.mktmpdir("mildred-test")

    FileUtils.touch(File.join(@dir, "file1.txt"))
    FileUtils.touch(File.join(@dir, "file2.rb"))
    FileUtils.mkdir(File.join(@dir, "subdir"))
    FileUtils.touch(File.join(@dir, ".hidden"))
  end

  def teardown
    FileUtils.rm_rf(@dir)
  end

  def test_lists_files_and_directories
    result = @tool.execute(path: @dir)
    names = result.map { |e| e[:name] }

    assert_includes names, "file1.txt"
    assert_includes names, "file2.rb"
    assert_includes names, "subdir"
  end

  def test_identifies_types
    result = @tool.execute(path: @dir)
    types = result.to_h { |e| [e[:name], e[:type]] }

    assert_equal "file", types["file1.txt"]
    assert_equal "directory", types["subdir"]
  end

  def test_includes_file_size
    File.write(File.join(@dir, "file1.txt"), "hello")
    result = @tool.execute(path: @dir)
    entry = result.find { |e| e[:name] == "file1.txt" }

    assert_equal 5, entry[:size]
  end

  def test_directory_size_is_nil
    result = @tool.execute(path: @dir)
    entry = result.find { |e| e[:name] == "subdir" }

    assert_nil entry[:size]
  end

  def test_hides_hidden_files_by_default
    result = @tool.execute(path: @dir)
    names = result.map { |e| e[:name] }

    refute_includes names, ".hidden"
  end

  def test_shows_hidden_files_when_requested
    result = @tool.execute(path: @dir, show_hidden: true)
    names = result.map { |e| e[:name] }

    assert_includes names, ".hidden"
  end

  def test_returns_error_for_nonexistent_path
    result = @tool.execute(path: "/nonexistent/path")

    assert_match(/does not exist/, result[:error])
  end
end
