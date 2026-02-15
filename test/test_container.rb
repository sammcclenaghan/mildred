# frozen_string_literal: true

require "test_helper"

class TestContainer < Minitest::Test
  def test_mount_args_with_directory_only
    job = build_job(directory: "/tmp/downloads", destinations: [])
    container = Mildred::Container.new(job: job)

    mount_args = container.send(:mount_args)

    assert_equal ["-v", "/tmp/downloads:/tmp/downloads"], mount_args
  end

  def test_mount_args_with_destinations
    job = build_job(
      directory: "/tmp/downloads",
      destinations: ["/tmp/archive", "/tmp/backup"]
    )
    container = Mildred::Container.new(job: job)

    mount_args = container.send(:mount_args)

    expected = [
      "-v", "/tmp/downloads:/tmp/downloads",
      "-v", "/tmp/archive:/tmp/archive",
      "-v", "/tmp/backup:/tmp/backup"
    ]
    assert_equal expected, mount_args
  end

  def test_mount_args_deduplicates_paths
    job = build_job(
      directory: "/tmp/downloads",
      destinations: ["/tmp/downloads", "/tmp/archive"]
    )
    container = Mildred::Container.new(job: job)

    mount_args = container.send(:mount_args)

    expected = [
      "-v", "/tmp/downloads:/tmp/downloads",
      "-v", "/tmp/archive:/tmp/archive"
    ]
    assert_equal expected, mount_args
  end

  def test_stop_is_safe_when_not_started
    job = build_job(directory: "/tmp/downloads", destinations: [])
    container = Mildred::Container.new(job: job)

    assert_nil container.stop
  end

  def test_containerfile_installs_bash
    assert_includes Mildred::Container::CONTAINERFILE, "bash"
    assert_includes Mildred::Container::CONTAINERFILE, "coreutils"
    assert_includes Mildred::Container::CONTAINERFILE, "findutils"
  end

  def test_cleanup_stale_does_not_error_with_no_stale_containers
    Mildred::Container.cleanup_stale
  end

  private

  def build_job(directory:, destinations:)
    Mildred::Job.send(:new,
      name: "Test Job",
      directory: directory,
      destinations: destinations,
      tasks: ["test task"]
    )
  end
end
