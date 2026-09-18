require "ruby_llm/tool"
require "fileutils"

class ListFiles < RubyLLM::Tool
  description "List the files and folders inside a directory. Folders end with a slash. Files show their size and last-modified date. Hidden files are not shown."
  param :path, desc: "Directory to list, e.g. downloads or downloads/photos"

  def execute(path:)
    entries = Dir.children(path).reject { |name| name.start_with?(".") }.sort.map do |name|
      full = File.join(path, name)
      next "#{name}/" if File.directory?(full)

      stat = File.stat(full)
      "#{name}  #{human_size(stat.size)}  #{stat.mtime.strftime("%Y-%m-%d")}"
    end
    entries.empty? ? "(empty)" : entries.join("\n")
  rescue => e
    "Error: #{e.message}"
  end

  private

  def human_size(bytes)
    return "#{bytes} B" if bytes < 1024

    units = %w[KB MB GB TB]
    value = bytes.to_f
    unit = nil
    units.each do |u|
      value /= 1024
      unit = u
      break if value < 1024
    end
    format("%.1f %s", value, unit)
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

module Mover
  private

  def dry_run?
    ENV["MILDRED_DRY_RUN"] == "1"
  end

  # "documents/" or an existing folder means "put it inside, keeping the name".
  def resolve(source, destination)
    return File.join(destination, File.basename(source)) if File.directory?(destination) || destination.end_with?("/")

    destination
  end

  def move(source, destination)
    return "Error: #{destination} already exists" if File.exist?(destination)
    return "Would move #{source} to #{destination}" if dry_run?

    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.mv(source, destination)
    "Moved #{source} to #{destination}"
  end
end

class MoveFile < RubyLLM::Tool
  include Mover

  description "Move or rename a single file. Missing destination folders are created. Never overwrites. Cannot move folders; use move_folder for that."
  param :source, desc: "Path of the file to move, e.g. downloads/report.pdf"
  param :destination, desc: "Where to move it, e.g. documents/report.pdf or documents/"

  def execute(source:, destination:)
    return "Error: #{source} does not exist" unless File.exist?(source)
    return "Error: #{source} is a folder; use move_folder" if File.directory?(source)

    move(source, resolve(source, destination))
  rescue => e
    "Error: #{e.message}"
  end
end

class MoveFolder < RubyLLM::Tool
  include Mover

  description "Move or rename a whole folder and everything in it. Only use this when the task explicitly asks to move a folder. Never overwrites."
  param :source, desc: "Path of the folder to move, e.g. downloads/photos"
  param :destination, desc: "Where to move it, e.g. pictures/photos or pictures/"

  def execute(source:, destination:)
    source = source.chomp("/")
    return "Error: #{source} does not exist" unless File.exist?(source)
    return "Error: #{source} is a file; use move_file" unless File.directory?(source)
    return "Error: #{source} is a top-level folder and cannot be moved" unless source.include?("/")

    destination = resolve(source, destination)
    return "Error: cannot move #{source} inside itself" if "#{destination}/".start_with?("#{source}/")

    move(source, destination)
  rescue => e
    "Error: #{e.message}"
  end
end
