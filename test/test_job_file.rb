# frozen_string_literal: true

require "test_helper"

class TestJob < Minitest::Test
  def test_parses_basic_job
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Downloads Organizer
            directory: /tmp/downloads
            tasks:
              - Trash all duplicate downloads
      YAML

      jobs = Mildred::Job.from_yaml(path)

      assert_equal 1, jobs.length
      job = jobs.first
      assert_equal "Downloads Organizer", job.name
      assert_equal "/tmp/downloads", job.directory
      assert_equal ["Trash all duplicate downloads"], job.tasks
    end
  end

  def test_parses_multiple_jobs
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Downloads Organizer
            directory: /tmp/downloads
            tasks:
              - Trash all duplicate downloads
          - name: Archive Old Docs
            directory: /tmp/documents
            tasks:
              - Move files older than 30 days
      YAML

      jobs = Mildred::Job.from_yaml(path)

      assert_equal 2, jobs.length
      assert_equal "Downloads Organizer", jobs[0].name
      assert_equal "Archive Old Docs", jobs[1].name
    end
  end

  def test_parses_destinations
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Archive Old Docs
            directory: /tmp/documents
            destinations:
              - /tmp/archive
              - /tmp/backup
            tasks:
              - Move files older than 30 days
      YAML

      jobs = Mildred::Job.from_yaml(path)
      job = jobs.first

      assert_equal ["/tmp/archive", "/tmp/backup"], job.destinations
    end
  end

  def test_defaults_destinations_to_empty
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Downloads Organizer
            directory: /tmp/downloads
            tasks:
              - Trash all duplicate downloads
      YAML

      jobs = Mildred::Job.from_yaml(path)
      job = jobs.first

      assert_equal [], job.destinations
    end
  end

  def test_expands_tilde_in_directory
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Downloads Organizer
            directory: ~/Downloads
            tasks:
              - Trash all duplicate downloads
      YAML

      jobs = Mildred::Job.from_yaml(path)
      job = jobs.first

      assert_equal File.join(Dir.home, "Downloads"), job.directory
    end
  end

  def test_expands_tilde_in_destinations
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Archive Old Docs
            directory: /tmp/documents
            destinations:
              - ~/Archive
            tasks:
              - Move files older than 30 days
      YAML

      jobs = Mildred::Job.from_yaml(path)
      job = jobs.first

      assert_equal [File.join(Dir.home, "Archive")], job.destinations
    end
  end

  def test_raises_on_missing_jobs_key
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        tasks:
          - name: Something
      YAML

      assert_raises(Mildred::Job::ParseError) do
        Mildred::Job.from_yaml(path)
      end
    end
  end

  def test_raises_on_missing_job_name
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - directory: /tmp/downloads
            tasks:
              - Trash all duplicate downloads
      YAML

      assert_raises(Mildred::Job::ParseError) do
        Mildred::Job.from_yaml(path)
      end
    end
  end

  def test_raises_on_missing_directory
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Downloads Organizer
            tasks:
              - Trash all duplicate downloads
      YAML

      assert_raises(Mildred::Job::ParseError) do
        Mildred::Job.from_yaml(path)
      end
    end
  end

  def test_raises_on_missing_tasks
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Downloads Organizer
            directory: /tmp/downloads
      YAML

      assert_raises(Mildred::Job::ParseError) do
        Mildred::Job.from_yaml(path)
      end
    end
  end

  def test_raises_on_empty_tasks
    Dir.mktmpdir do |dir|
      path = File.join(dir, "jobs.yml")
      File.write(path, <<~YAML)
        jobs:
          - name: Downloads Organizer
            directory: /tmp/downloads
            tasks: []
      YAML

      assert_raises(Mildred::Job::ParseError) do
        Mildred::Job.from_yaml(path)
      end
    end
  end
end
