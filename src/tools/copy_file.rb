require "ruby_llm/tool"
require "fileutils"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class CopyFile < RubyLLM::Tool
    include Loggable
    include DryRunnable

    description "Copy a file or directory from source to destination"
    param :source, desc: "The source file or directory path to copy"
    param :destination, desc: "The destination path where the file or directory will be copied"
    param :force, desc: "Whether to overwrite existing files", required: false

    def initialize(navigation_tool: nil)
      super()
      @navigation_tool = navigation_tool
    end

    def execute(source:, destination:, force: false)
      # Use navigation tool's current path if available, otherwise use process working directory
      base_path = @navigation_tool&.current_path || Dir.pwd
      full_source = File.expand_path(source, base_path)
      full_destination = File.expand_path(destination, base_path)

      unless File.exist?(full_source)
        return { error: "Source not found: #{source}" }
      end

      dest_dir = File.directory?(full_destination) ? full_destination : File.dirname(full_destination)
      unless File.directory?(dest_dir)
        return { error: "Destination directory does not exist: #{dest_dir}" }
      end

      if File.exist?(full_destination) && !force
        return { error: "Destination already exists. Use force: true to overwrite" }
      end

      if self.class.dry_run_mode?
        info "[DRY RUN] Would copy #{full_source} to #{full_destination}"
        return {
          dry_run: true,
          would_copy: {
            from: full_source,
            to: full_destination,
            force: force
          }
        }
      end

      begin
        FileUtils.cp_r(full_source, full_destination, preserve: true)
        info "Successfully copied #{full_source} to #{full_destination}"
        {
          success: true,
          source: source,
          destination: destination,
          full_source: full_source,
          full_destination: full_destination
        }
      rescue => e
        error "Copy failed: #{e.message}"
        { error: e.message }
      end
    end
  end
end
