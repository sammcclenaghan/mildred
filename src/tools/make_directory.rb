require "ruby_llm/tool"
require "fileutils"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class MakeDirectory < RubyLLM::Tool
    include Loggable
    include DryRunnable

    description "Create a new directory and optionally create parent directories"
    param :path, desc: "The path of the directory to create"
    param :parents, desc: "Whether to create parent directories as needed", required: false

    def execute(path:, parents: true)
      target_path = File.expand_path(path)

      if File.exist?(target_path)
        if File.directory?(target_path)
          return { error: "Directory already exists: #{path}" }
        else
          return { error: "A file already exists at this path: #{path}" }
        end
      end

      if self.class.dry_run_mode?
        info "[DRY RUN] Would create directory: #{target_path}"
        info "[DRY RUN] Would create parent directories" if parents
        return {
          dry_run: true,
          would_create: {
            path: target_path,
            parents: parents
          }
        }
      end

      begin
        if parents
          FileUtils.mkdir_p(target_path)
        else
          FileUtils.mkdir(target_path)
        end

        info "Successfully created directory: #{target_path}"
        {
          success: true,
          created: target_path,
          parents_created: parents
        }
      rescue => e
        error "Failed to create directory: #{e.message}"
        { 
          error: e.message,
          path: target_path
        }
      end
    end
  end
end