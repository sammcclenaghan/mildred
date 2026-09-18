require_relative "test_helper"

class ListFilesTest < Minitest::Test
  include WorkspaceHelper

  def test_lists_sorted_entries_with_folders_marked
    with_workspace("downloads/b.pdf" => "", "downloads/a.pdf" => "", "downloads/photos/x.jpg" => "") do
      assert_equal "a.pdf\nb.pdf\nphotos/", ListFiles.new.execute(path: "downloads")
    end
  end

  def test_empty_folder
    with_workspace { assert_equal "(empty)", ListFiles.new.execute(path: "documents") }
  end

  def test_missing_folder_reports_error
    with_workspace { assert_match(/^Error: /, ListFiles.new.execute(path: "nope")) }
  end
end

class ReadFileTest < Minitest::Test
  include WorkspaceHelper

  def test_reads_contents
    with_workspace("downloads/notes.txt" => "hello") do
      assert_equal "hello", ReadFile.new.execute(path: "downloads/notes.txt")
    end
  end

  def test_truncates_large_files
    with_workspace("downloads/big.txt" => "x" * 10_000) do
      assert_equal 4000, ReadFile.new.execute(path: "downloads/big.txt").length
    end
  end

  def test_missing_file_reports_error
    with_workspace { assert_match(/^Error: /, ReadFile.new.execute(path: "downloads/nope.txt")) }
  end
end

class MoveFileTest < Minitest::Test
  include WorkspaceHelper

  def setup
    @tool = MoveFile.new
  end

  def test_moves_to_explicit_path
    with_workspace("downloads/a.pdf" => "a") do
      assert_equal "Moved downloads/a.pdf to documents/a.pdf", @tool.execute(source: "downloads/a.pdf", destination: "documents/a.pdf")
      assert File.exist?("documents/a.pdf")
      refute File.exist?("downloads/a.pdf")
    end
  end

  def test_moves_into_existing_folder
    with_workspace("downloads/a.pdf" => "a") do
      assert_equal "Moved downloads/a.pdf to documents/a.pdf", @tool.execute(source: "downloads/a.pdf", destination: "documents")
      assert File.exist?("documents/a.pdf")
    end
  end

  def test_trailing_slash_means_folder_and_creates_it
    with_workspace("downloads/song.mp3" => "") do
      assert_equal "Moved downloads/song.mp3 to downloads/music/song.mp3", @tool.execute(source: "downloads/song.mp3", destination: "downloads/music/")
      assert File.exist?("downloads/music/song.mp3")
    end
  end

  def test_creates_missing_parent_folders
    with_workspace("downloads/a.pdf" => "") do
      @tool.execute(source: "downloads/a.pdf", destination: "documents/2026/reports/a.pdf")
      assert File.exist?("documents/2026/reports/a.pdf")
    end
  end

  def test_never_overwrites
    with_workspace("downloads/a.pdf" => "new", "documents/a.pdf" => "old") do
      assert_equal "Error: documents/a.pdf already exists", @tool.execute(source: "downloads/a.pdf", destination: "documents/")
      assert_equal "old", File.read("documents/a.pdf")
      assert_equal "new", File.read("downloads/a.pdf")
    end
  end

  def test_missing_source_reports_error
    with_workspace do
      assert_equal "Error: downloads/nope.pdf does not exist", @tool.execute(source: "downloads/nope.pdf", destination: "documents/")
    end
  end

  def test_dry_run_moves_nothing
    with_workspace("downloads/a.pdf" => "") do
      ENV["MILDRED_DRY_RUN"] = "1"
      assert_equal "Would move downloads/a.pdf to documents/a.pdf", @tool.execute(source: "downloads/a.pdf", destination: "documents/")
      assert File.exist?("downloads/a.pdf")
      refute File.exist?("documents/a.pdf")
    ensure
      ENV.delete("MILDRED_DRY_RUN")
    end
  end
end
