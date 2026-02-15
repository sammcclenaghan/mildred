# frozen_string_literal: true

require "test_helper"

class TestLogger < Minitest::Test
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
end
