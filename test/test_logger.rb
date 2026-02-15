# frozen_string_literal: true

require "test_helper"

class TestLogger < Minitest::Test
  def setup
    @log_path = File.join(Dir.mktmpdir, "mildred.log")
    @original_path = Mildred::Logger::LOG_PATH
    Mildred::Logger.send(:remove_const, :LOG_PATH)
    Mildred::Logger.const_set(:LOG_PATH, @log_path)
  end

  def teardown
    Mildred::Logger.send(:remove_const, :LOG_PATH)
    Mildred::Logger.const_set(:LOG_PATH, @original_path)
    Mildred::Current.reset
  end

  def test_starts_empty
    logger = Mildred::Logger.new

    assert_empty logger.entries
  end

  def test_logs_entries
    logger = Mildred::Logger.new

    logger.log("ls", "file.txt\n", "", 0)

    assert_equal 1, logger.entries.length
    entry = logger.entries.first
    assert_equal "ls", entry[:command]
    assert_equal "file.txt\n", entry[:stdout]
    assert_equal "", entry[:stderr]
    assert_equal 0, entry[:exit_code]
  end

  def test_logs_multiple_entries
    logger = Mildred::Logger.new

    logger.log("echo a", "a\n", "", 0)
    logger.log("echo b", "b\n", "", 0)

    assert_equal 2, logger.entries.length
  end

  def test_clear_resets_entries
    logger = Mildred::Logger.new

    logger.log("echo a", "a\n", "", 0)
    logger.clear

    assert_empty logger.entries
  end

  def test_writes_command_to_log_file
    logger = Mildred::Logger.new

    logger.log("ls -la", "output\n", "", 0)

    content = File.read(@log_path)
    assert_includes content, "event=exec"
    assert_includes content, "command=\"ls -la\""
    assert_includes content, "exit_code=0"
  end

  def test_writes_job_context_to_log_file
    Mildred::Current.job_name = "Clean Downloads"
    logger = Mildred::Logger.new

    logger.log("ls", "output\n", "", 0)

    content = File.read(@log_path)
    assert_includes content, "job=\"Clean Downloads\""
  end

  def test_log_job_start
    logger = Mildred::Logger.new

    logger.log_job_start("Clean Downloads")

    content = File.read(@log_path)
    assert_includes content, "job=\"Clean Downloads\""
    assert_includes content, "event=started"
  end

  def test_log_job_end_success
    logger = Mildred::Logger.new

    logger.log_job_end("Clean Downloads", success: true)

    content = File.read(@log_path)
    assert_includes content, "job=\"Clean Downloads\""
    assert_includes content, "event=completed"
    assert_includes content, "status=success"
  end

  def test_log_job_end_error
    logger = Mildred::Logger.new

    logger.log_job_end("Clean Downloads", success: false)

    content = File.read(@log_path)
    assert_includes content, "status=error"
  end
end
