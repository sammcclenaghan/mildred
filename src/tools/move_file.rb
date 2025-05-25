require "ruby_llm/tool"
require "fileutils"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class MoveFile < RubyLLM::Tool
    include Loggable
    include DryRunnable

    description "Move a file or directory from source to destination"
    param :source, desc: "The source file or directory path to move"
    param :destination, desc: "The destination path where the file or directory will be moved"
    param :force, desc: "Whether to overwrite existing files", required: false

    def execute(source:, destination:, force: false)
      unless File.exist?(source)
        return { error: "Source not found: #{source}" }
      end

      dest_dir = File.directory?(destination) ? destination : File.dirname(destination)
      unless File.directory?(dest_dir)
        return { error: "Destination directory does not exist: #{dest_dir}" }
      end

      if File.exist?(destination) && !force
        return { error: "Destination already exists. Use force: true to overwrite" }
      end

      if self.class.dry_run_mode?
        info "[DRY RUN] Would move #{source} to #{destination}"
        return {
          dry_run: true,
          would_move: {
            from: source,
            to: destination,
            force: force
          }
        }
      end

      begin
        FileUtils.mv(source, destination, force: force)
        info "Successfully moved #{source} to #{destination}"
        {
          success: true,
          source: source,
          destination: destination
        }
      rescue => e
        error "Move failed: #{e.message}"
        { error: e.message }
      end
    end
  end
end