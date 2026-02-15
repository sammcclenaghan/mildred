# frozen_string_literal: true

require "test_helper"

class TestRunner < Minitest::Test
  FIXTURE_DIR = File.expand_path("fixtures/sample_dir", __dir__)

  def setup
    FileUtils.rm_rf(FIXTURE_DIR)
    FileUtils.mkdir_p(FIXTURE_DIR)
  end

  def teardown
    FileUtils.rm_rf(FIXTURE_DIR)
    FileUtils.mkdir_p(FIXTURE_DIR)
  end

  def test_initializes_with_jobs_from_yaml
    Dir.mktmpdir do |dir|
      path = write_rules(dir, <<~YAML)
        jobs:
          - name: Clean Downloads
            directory: /tmp/downloads
            tasks:
              - Delete duplicate files
          - name: Sort Documents
            directory: /tmp/documents
            tasks:
              - Organize by file type
      YAML

      runner = Mildred::Runner.new(path: path)

      assert_equal 2, runner.jobs.length
      assert_equal "Clean Downloads", runner.jobs[0].name
      assert_equal "Sort Documents", runner.jobs[1].name
    end
  end

  def test_raises_on_invalid_yaml
    Dir.mktmpdir do |dir|
      path = write_rules(dir, <<~YAML)
        not_jobs:
          - something: wrong
      YAML

      assert_raises(Mildred::Job::ParseError) do
        Mildred::Runner.new(path: path)
      end
    end
  end

  def test_build_prompt_with_tasks
    Dir.mktmpdir do |dir|
      path = write_rules(dir, <<~YAML)
        jobs:
          - name: Clean Downloads
            directory: /tmp/downloads
            tasks:
              - Delete duplicate files
              - Remove empty folders
      YAML

      runner = Mildred::Runner.new(path: path)
      prompt = runner.send(:build_prompt, runner.jobs.first)

      assert_includes prompt, "You are organizing the directory: /tmp/downloads"
      assert_includes prompt, "1. Delete duplicate files"
      assert_includes prompt, "2. Remove empty folders"
      assert_includes prompt, "Do not ask questions"
    end
  end

  def test_build_prompt_without_destinations
    Dir.mktmpdir do |dir|
      path = write_rules(dir, <<~YAML)
        jobs:
          - name: Clean Downloads
            directory: /tmp/downloads
            tasks:
              - Delete duplicate files
      YAML

      runner = Mildred::Runner.new(path: path)
      prompt = runner.send(:build_prompt, runner.jobs.first)

      refute_includes prompt, "Available destinations"
    end
  end

  def test_build_prompt_with_destinations
    Dir.mktmpdir do |dir|
      path = write_rules(dir, <<~YAML)
        jobs:
          - name: Archive Old Files
            directory: /tmp/downloads
            destinations:
              - /tmp/archive
              - /tmp/backup
            tasks:
              - Move old files to archive
      YAML

      runner = Mildred::Runner.new(path: path)
      prompt = runner.send(:build_prompt, runner.jobs.first)

      assert_includes prompt, "Available destinations: /tmp/archive, /tmp/backup"
    end
  end

  def test_execute_job_moves_files
    File.write(File.join(FIXTURE_DIR, "notes.txt"), "some notes")
    File.write(File.join(FIXTURE_DIR, "readme.txt"), "readme content")

    Dir.mktmpdir do |dir|
      dest_dir = File.join(dir, "text_files")

      path = write_rules(dir, <<~YAML)
        jobs:
          - name: Sort by Type
            directory: #{FIXTURE_DIR}
            destinations:
              - #{dest_dir}
            tasks:
              - Move all .txt files to #{dest_dir}
      YAML

      VCR.use_cassette("runner_move_files") do
        runner = Mildred::Runner.new(path: path)
        result = runner.send(:execute_job, runner.jobs.first)

        assert result, "Expected job to succeed"
      end
    end
  end

  def test_default_rules_path
    expected = File.join(Dir.home, ".mildred", "rules.yml")
    assert_equal expected, Mildred::Runner::DEFAULT_RULES_PATH
  end

  def test_initializes_with_noop_false_by_default
    Dir.mktmpdir do |dir|
      path = write_rules(dir, <<~YAML)
        jobs:
          - name: Clean Downloads
            directory: /tmp/downloads
            tasks:
              - Delete duplicate files
      YAML

      runner = Mildred::Runner.new(path: path)

      assert_equal false, runner.noop
    end
  end

  def test_initializes_with_noop_true
    Dir.mktmpdir do |dir|
      path = write_rules(dir, <<~YAML)
        jobs:
          - name: Clean Downloads
            directory: /tmp/downloads
            tasks:
              - Delete duplicate files
      YAML

      runner = Mildred::Runner.new(path: path, noop: true)

      assert_equal true, runner.noop
    end
  end

  private

  def write_rules(dir, content)
    path = File.join(dir, "rules.yml")
    File.write(path, content)
    path
  end
end
