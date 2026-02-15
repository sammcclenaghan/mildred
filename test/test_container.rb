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

  def test_accepts_custom_image
    job = build_job(directory: "/tmp/downloads", destinations: [])
    container = Mildred::Container.new(job: job, image: "ubuntu:24.04")

    assert_instance_of Mildred::Container, container
  end

  def test_stop_is_safe_when_not_started
    job = build_job(directory: "/tmp/downloads", destinations: [])
    container = Mildred::Container.new(job: job)

    assert_nil container.stop
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
