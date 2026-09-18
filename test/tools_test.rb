require_relative "test_helper"

class ListFilesTest < Minitest::Test
  include WorkspaceHelper

  def test_lists_sorted_entries_with_size_and_date
    with_workspace("downloads/b.pdf" => "x" * 2048, "downloads/a.pdf" => "abc", "downloads/photos/x.jpg" => "") do
      today = Time.now.strftime("%Y-%m-%d")
      expected = ["a.pdf  3 B  #{today}", "b.pdf  2.0 KB  #{today}", "photos/"]
      assert_equal expected, ListFiles.new.execute(path: "downloads").lines(chomp: true)
    end
  end

  def test_human_sizes
    tool = ListFiles.new
    assert_equal "512 B", tool.send(:human_size, 512)
    assert_equal "1.5 MB", tool.send(:human_size, 1_572_864)
    assert_equal "2.0 GB", tool.send(:human_size, 2 * 1024**3)
  end

  def test_empty_folder
    with_workspace { assert_equal "(empty)", ListFiles.new.execute(path: "documents") }
  end

  def test_hides_dotfiles
    with_workspace("downloads/.DS_Store" => "", "downloads/.report.pdf.icloud" => "", "downloads/a.pdf" => "") do
      assert_equal ["a.pdf"], ListFiles.new.execute(path: "downloads").lines(chomp: true).map { |l| l.split("  ").first }
    end
  end

  def test_folder_of_only_dotfiles_is_empty
    with_workspace("downloads/.DS_Store" => "") { assert_equal "(empty)", ListFiles.new.execute(path: "downloads") }
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

  def test_refuses_to_move_folders
    with_workspace("downloads/photos/x.jpg" => "") do
      assert_equal "Error: downloads/photos is a folder; use move_folder", @tool.execute(source: "downloads/photos", destination: "documents/")
      assert File.exist?("downloads/photos/x.jpg")
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

class MoveFolderTest < Minitest::Test
  include WorkspaceHelper

  def setup
    @tool = MoveFolder.new
  end

  def test_moves_folder_with_contents
    with_workspace("downloads/photos/x.jpg" => "", "downloads/photos/y.jpg" => "") do
      assert_equal "Moved downloads/photos to documents/photos", @tool.execute(source: "downloads/photos", destination: "documents/")
      assert File.exist?("documents/photos/x.jpg")
      refute File.exist?("downloads/photos")
    end
  end

  def test_renames_folder
    with_workspace("downloads/photos/x.jpg" => "") do
      assert_equal "Moved downloads/photos to documents/2026/pictures", @tool.execute(source: "downloads/photos/", destination: "documents/2026/pictures")
      assert File.exist?("documents/2026/pictures/x.jpg")
    end
  end

  def test_never_overwrites
    with_workspace("downloads/photos/x.jpg" => "", "documents/photos/old.jpg" => "") do
      assert_equal "Error: documents/photos already exists", @tool.execute(source: "downloads/photos", destination: "documents/")
      assert File.exist?("documents/photos/old.jpg")
      assert File.exist?("downloads/photos/x.jpg")
    end
  end

  def test_refuses_files
    with_workspace("downloads/a.pdf" => "") do
      assert_equal "Error: downloads/a.pdf is a file; use move_file", @tool.execute(source: "downloads/a.pdf", destination: "documents/")
    end
  end

  def test_refuses_top_level_folders
    with_workspace do
      assert_equal "Error: downloads is a top-level folder and cannot be moved", @tool.execute(source: "downloads", destination: "documents/")
      assert Dir.exist?("downloads")
    end
  end

  def test_refuses_moving_into_itself
    with_workspace("downloads/photos/x.jpg" => "") do
      assert_equal "Error: cannot move downloads/photos inside itself", @tool.execute(source: "downloads/photos", destination: "downloads/photos/nested")
      assert File.exist?("downloads/photos/x.jpg")
    end
  end

  def test_dry_run_moves_nothing
    with_workspace("downloads/photos/x.jpg" => "") do
      ENV["MILDRED_DRY_RUN"] = "1"
      assert_equal "Would move downloads/photos to documents/photos", @tool.execute(source: "downloads/photos", destination: "documents/")
      assert File.exist?("downloads/photos/x.jpg")
    ensure
      ENV.delete("MILDRED_DRY_RUN")
    end
  end
end
