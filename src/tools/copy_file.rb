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
        info "[DRY RUN] Would copy #{source} to #{destination}"
        return {
          dry_run: true,
          would_copy: {
            from: source,
            to: destination,
            force: force
          }
        }
      end

      begin
        FileUtils.cp_r(source, destination, preserve: true)
        info "Successfully copied #{source} to #{destination}"
        {
          success: true,
          source: source,
          destination: destination
        }
      rescue => e
        error "Copy failed: #{e.message}"
        { error: e.message }
      end
    end
  end
end