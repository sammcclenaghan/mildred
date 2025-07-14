require "ruby_llm/tool"
require "fileutils"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class DiskSpace < RubyLLM::Tool
    include Loggable
    include DryRunnable

    CATEGORIES = {
      documents: %w[.pdf .doc .docx .txt .rtf .md .pages .odt],
      images: %w[.jpg .jpeg .png .gif .bmp .svg .raw .tiff .webp],
      audio: %w[.mp3 .wav .flac .m4a .aac .ogg],
      video: %w[.mp4 .avi .mov .wmv .mkv .flv .webm],
      archives: %w[.zip .rar .7z .tar .gz .bz2],
      code: %w[.rb .py .js .java .cpp .h .php .css .html .swift]
    }

    SIZE_UNITS = {
      TB: 1024 ** 4,
      GB: 1024 ** 3,
      MB: 1024 ** 2,
      KB: 1024
    }

    description "Analyze disk space usage in a directory"
    param :path, desc: "Directory path to analyze"
    param :depth, desc: "Maximum depth for directory traversal (0 for unlimited)", required: false

    def execute(path:, depth: 0)
      unless File.directory?(path)
        return { error: "Not a directory: #{path}" }
      end

      if self.class.dry_run_mode?
        info "[DRY RUN] Would analyze disk space for: #{path}"
        return {
          dry_run: true,
          would_analyze: {
            path: path,
            depth: depth
          }
        }
      end

      begin
        stats = analyze_directory(path, depth)
        format_results(stats)
      rescue => e
        error "Analysis failed: #{e.message}"
        { error: e.message }
      end
    end

    private

    def analyze_directory(path, max_depth, current_depth = 0)
      stats = {
        total_size: 0,
        file_count: 0,
        dir_count: 0,
        by_category: Hash.new { |h, k| h[k] = { size: 0, count: 0 } },
        by_size: Hash.new { |h, k| h[k] = { size: 0, count: 0 } },
        largest_files: []
      }

      Dir.each_child(path) do |entry|
        full_path = File.join(path, entry)
        
        if File.directory?(full_path)
          stats[:dir_count] += 1
          if max_depth == 0 || current_depth < max_depth
            sub_stats = analyze_directory(full_path, max_depth, current_depth + 1)
            merge_stats!(stats, sub_stats)
          end
        else
          file_size = File.size(full_path)
          stats[:total_size] += file_size
          stats[:file_count] += 1
          
          # Categorize by file type
          category = categorize_file(full_path)
          stats[:by_category][category][:size] += file_size
          stats[:by_category][category][:count] += 1
          
          # Categorize by size
          size_category = categorize_size(file_size)
          stats[:by_size][size_category][:size] += file_size
          stats[:by_size][size_category][:count] += 1
          
          # Track largest files
          stats[:largest_files] << { path: full_path, size: file_size }
          stats[:largest_files].sort_by! { |f| -f[:size] }
          stats[:largest_files] = stats[:largest_files].first(10)
        end
      end

      stats
    end

    def merge_stats!(target, source)
      target[:total_size] += source[:total_size]
      target[:file_count] += source[:file_count]
      target[:dir_count] += source[:dir_count]
      
      source[:by_category].each do |category, data|
        target[:by_category][category][:size] += data[:size]
        target[:by_category][category][:count] += data[:count]
      end
      
      source[:by_size].each do |size_range, data|
        target[:by_size][size_range][:size] += data[:size]
        target[:by_size][size_range][:count] += data[:count]
      end
      
      target[:largest_files].concat(source[:largest_files])
      target[:largest_files].sort_by! { |f| -f[:size] }
      target[:largest_files] = target[:largest_files].first(10)
    end

    def categorize_file(path)
      ext = File.extname(path).downcase
      CATEGORIES.find { |category, extensions| extensions.include?(ext) }&.first || :other
    end

    def categorize_size(size)
      case size
      when 0...1024 then "< 1KB"
      when 1024...(1024**2) then "1KB-1MB"
      when (1024**2)...(1024**3) then "1MB-1GB"
      else "> 1GB"
      end
    end

    def format_size(bytes)
      SIZE_UNITS.each do |unit, divisor|
        if bytes >= divisor
          return "#{(bytes.to_f / divisor).round(2)} #{unit}"
        end
      end
      "#{bytes} B"
    end

    def format_results(stats)
      {
        summary: {
          total_size: format_size(stats[:total_size]),
          total_files: stats[:file_count],
          total_directories: stats[:dir_count]
        },
        by_category: stats[:by_category].transform_values { |data|
          {
            size: format_size(data[:size]),
            count: data[:count]
          }
        },
        by_size: stats[:by_size].transform_values { |data|
          {
            size: format_size(data[:size]),
            count: data[:count]
          }
        },
        largest_files: stats[:largest_files].map { |file|
          {
            path: file[:path],
            size: format_size(file[:size])
          }
        }
      }
    end
  end
end