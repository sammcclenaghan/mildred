require "ruby_llm/tool"
require "fileutils"

class ListFiles < RubyLLM::Tool
  description "List the files and folders inside a directory. Folders end with a slash."
  param :path, desc: "Directory to list, e.g. downloads or downloads/photos"

  def execute(path:)
    entries = Dir.children(path).sort.map { |f| File.directory?(File.join(path, f)) ? "#{f}/" : f }
    entries.empty? ? "(empty)" : entries.join("\n")
  rescue => e
    "Error: #{e.message}"
  end
end

class ReadFile < RubyLLM::Tool
  description "Read the first part of a text file. Only use this when the name alone is not enough to decide."
  param :path, desc: "Path of the file to read, e.g. downloads/notes.txt"

  def execute(path:)
    File.read(path, 4000)
  rescue => e
    "Error: #{e.message}"
  end
end

class MoveFile < RubyLLM::Tool
  description "Move or rename a file. Missing destination folders are created. Never overwrites an existing file."
  param :source, desc: "Path of the file to move, e.g. downloads/report.pdf"
  param :destination, desc: "Where to move it, e.g. documents/report.pdf or documents/"

  def execute(source:, destination:)
    return "Error: #{source} does not exist" unless File.exist?(source)

    destination = File.join(destination, File.basename(source)) if File.directory?(destination) || destination.end_with?("/")
    return "Error: #{destination} already exists" if File.exist?(destination)
    return "Would move #{source} to #{destination}" if dry_run?

    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.mv(source, destination)
    "Moved #{source} to #{destination}"
  rescue => e
    "Error: #{e.message}"
  end

  private

  def dry_run?
    ENV["MILDRED_DRY_RUN"] == "1"
  end
end
