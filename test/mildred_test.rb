require_relative "test_helper"

class InitTest < Minitest::Test
  def test_writes_template
    Dir.mktmpdir do |dir|
      path = File.join(dir, "mildred.yml")
      capture_io { Mildred.init(path) }
      config = YAML.load_file(path)
      assert_equal "qwen2.5:7b", config.dig("settings", "model")
      assert_equal 1, config["jobs"].length
    end
  end

  def test_refuses_to_overwrite
    Dir.mktmpdir do |dir|
      path = File.join(dir, "mildred.yml")
      File.write(path, "keep me")
      assert_raises(Mildred::Error) { Mildred.init(path) }
      assert_equal "keep me", File.read(path)
    end
  end
end

class DirectoriesTest < Minitest::Test
  def test_named_directories_are_expanded
    Dir.mktmpdir do |dir|
      job = { "name" => "x", "directories" => { "downloads" => dir, :documents => dir } }
      assert_equal({ "downloads" => dir, "documents" => dir }, Mildred.directories(job))
    end
  end

  def test_single_directory_is_mounted_under_its_lowercased_name
    Dir.mktmpdir do |dir|
      desktop = File.join(dir, "Desktop")
      Dir.mkdir(desktop)
      assert_equal({ "desktop" => desktop }, Mildred.directories({ "name" => "x", "directory" => desktop }))
    end
  end

  def test_missing_directory_raises
    err = assert_raises(Mildred::Error) { Mildred.directories({ "name" => "x", "directory" => "/no/such/place" }) }
    assert_match(/does not exist/, err.message)
  end

  def test_job_without_directories_raises
    err = assert_raises(Mildred::Error) { Mildred.directories({ "name" => "x" }) }
    assert_match(/needs a 'directory' or 'directories'/, err.message)
  end
end

class ContainerCommandTest < Minitest::Test
  def test_builds_mounts_env_and_tasks
    Dir.mktmpdir do |dir|
      job = { "name" => "x", "directories" => { "downloads" => dir }, "tasks" => ["Sort it", "Then tidy"] }
      cmd = Mildred.container_command(job, host: "192.168.64.1", port: 11434, model: "qwen2.5:7b", dry_run: true)

      assert_equal %w[container run --rm], cmd.first(3)
      assert_includes cmd.each_cons(2).to_a, ["--volume", "#{dir}:/workspace/downloads"]
      assert_includes cmd, "OLLAMA_API_BASE=http://192.168.64.1:11434/v1"
      assert_includes cmd, "MILDRED_MODEL=qwen2.5:7b"
      assert_includes cmd, "MILDRED_DRY_RUN=1"
      assert_equal ["mildred", "Sort it", "Then tidy"], cmd.last(3)
    end
  end

  def test_job_without_tasks_raises
    Dir.mktmpdir do |dir|
      job = { "name" => "x", "directory" => dir }
      err = assert_raises(Mildred::Error) { Mildred.container_command(job, host: "h", port: 1, model: "m", dry_run: false) }
      assert_match(/has no tasks/, err.message)
    end
  end
end

class OllamaCheckTest < Minitest::Test
  def test_passes_when_reachable
    stub_request(:get, "http://192.168.64.1:11434/").to_return(body: "Ollama is running")
    Mildred.check_ollama!("192.168.64.1", 11434)
    assert_requested :get, "http://192.168.64.1:11434/"
  end

  def test_explains_when_unreachable
    stub_request(:get, "http://192.168.64.1:11434/").to_timeout
    err = assert_raises(Mildred::Error) { Mildred.check_ollama!("192.168.64.1", 11434) }
    assert_match(/cannot reach Ollama at 192.168.64.1:11434/, err.message)
    assert_match(/OLLAMA_HOST=0.0.0.0/, err.message)
  end

  def test_explains_when_refused
    stub_request(:get, "http://192.168.64.1:11434/").to_raise(Errno::ECONNREFUSED)
    assert_raises(Mildred::Error) { Mildred.check_ollama!("192.168.64.1", 11434) }
  end
end

class CleanTest < Minitest::Test
  def test_missing_config_raises
    Dir.mktmpdir do |dir|
      err = assert_raises(Mildred::Error) { Mildred.clean(["-c", File.join(dir, "nope.yml")]) }
      assert_match(/not found/, err.message)
    end
  end

  def test_config_without_jobs_raises
    Dir.mktmpdir do |dir|
      path = File.join(dir, "mildred.yml")
      File.write(path, "settings: {}\n")
      err = assert_raises(Mildred::Error) { Mildred.clean(["-c", path]) }
      assert_match(/no jobs/, err.message)
    end
  end

  def test_runs_each_job_with_settings
    Dir.mktmpdir do |dir|
      path = File.join(dir, "mildred.yml")
      File.write(path, <<~YAML)
        settings:
          model: llama3.1:8b
          ollama: { host: 10.0.0.5, port: 1234 }
        jobs:
          - { name: One, directory: #{dir}, tasks: [a] }
          - { name: Two, directory: #{dir}, tasks: [b] }
      YAML
      stub_request(:get, "http://10.0.0.5:1234/").to_return(body: "ok")

      ran = []
      runner = ->(job, **settings) { ran << [job["name"], settings] }
      Mildred.stub(:image_exists?, true) do
        Mildred.stub(:run_job, runner) do
          capture_io { Mildred.clean(["-n", "-c", path]) }
        end
      end

      expected = { host: "10.0.0.5", port: 1234, model: "llama3.1:8b", dry_run: true }
      assert_equal [["One", expected], ["Two", expected]], ran
    end
  end

  def test_job_flag_runs_only_that_job
    with_two_jobs do |path|
      ran = run_clean(["-c", path, "--job", "two"])
      assert_equal ["Two"], ran
    end
  end

  def test_job_flag_with_unknown_name_raises
    with_two_jobs do |path|
      err = assert_raises(Mildred::Error) { run_clean(["-c", path, "-j", "Nope"]) }
      assert_match(/no job named 'Nope'/, err.message)
    end
  end

  private

  def with_two_jobs
    Dir.mktmpdir do |dir|
      path = File.join(dir, "mildred.yml")
      File.write(path, <<~YAML)
        jobs:
          - { name: One, directory: #{dir}, tasks: [a] }
          - { name: Two, directory: #{dir}, tasks: [b] }
      YAML
      stub_request(:get, "http://192.168.64.1:11434/").to_return(body: "ok")
      yield path
    end
  end

  def run_clean(argv)
    ran = []
    Mildred.stub(:image_exists?, true) do
      Mildred.stub(:run_job, ->(job, **) { ran << job["name"] }) do
        capture_io { Mildred.clean(argv) }
      end
    end
    ran
  end
end
