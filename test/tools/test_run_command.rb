# frozen_string_literal: true

require "test_helper"

class TestRunCommand < Minitest::Test
  def setup
    Mildred.logger.clear
  end

  def test_executes_command_and_returns_output
    tool = Mildred::Tools::RunCommand.new

    result = tool.execute(command: "echo hello")

    assert_equal "hello\n", result[:stdout]
    assert_equal "", result[:stderr]
    assert_equal 0, result[:exit_code]
  end

  def test_returns_stderr_on_failure
    tool = Mildred::Tools::RunCommand.new

    result = tool.execute(command: "ls /nonexistent_path_xyz")

    refute_equal 0, result[:exit_code]
    refute_empty result[:stderr]
  end

  def test_logs_command_execution
    tool = Mildred::Tools::RunCommand.new

    tool.execute(command: "echo hello")
    tool.execute(command: "echo world")

    entries = Mildred.logger.entries
    assert_equal 2, entries.length
    assert_equal "echo hello", entries[0][:command]
    assert_equal "hello\n", entries[0][:stdout]
    assert_equal 0, entries[0][:exit_code]
    assert_equal "echo world", entries[1][:command]
  end

  def test_handles_multiline_output
    tool = Mildred::Tools::RunCommand.new

    result = tool.execute(command: "printf 'line1\nline2\nline3'")

    assert_equal "line1\nline2\nline3", result[:stdout]
  end

  def test_handles_file_operations
    Dir.mktmpdir do |dir|
      tool = Mildred::Tools::RunCommand.new

      tool.execute(command: "touch #{dir}/test.txt")
      result = tool.execute(command: "ls #{dir}")

      assert_includes result[:stdout], "test.txt"
    end
  end

  def test_noop_mode_does_not_execute_command
    Mildred::Current.noop = true
    tool = Mildred::Tools::RunCommand.new

    result = tool.execute(command: "echo should_not_run")

    assert_includes result[:stdout], "[noop] would execute: echo should_not_run"
    assert_equal 0, result[:exit_code]
    assert_empty result[:stderr]

    entries = Mildred.logger.entries
    assert_equal 1, entries.length
    assert_includes entries[0][:stdout], "[noop]"
  ensure
    Mildred::Current.reset
  end

  def test_handles_glob_moves
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "images"))
      File.write(File.join(dir, "a.jpg"), "img1")
      File.write(File.join(dir, "b.jpg"), "img2")
      File.write(File.join(dir, "c.txt"), "text")

      tool = Mildred::Tools::RunCommand.new
      tool.execute(command: "mv #{dir}/*.jpg #{dir}/images/")

      assert File.exist?(File.join(dir, "images", "a.jpg"))
      assert File.exist?(File.join(dir, "images", "b.jpg"))
      assert File.exist?(File.join(dir, "c.txt"))
      refute File.exist?(File.join(dir, "a.jpg"))
    end
  end
end
