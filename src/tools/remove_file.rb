require "ruby_llm/tool"
require "fileutils"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class RemoveFile < RubyLLM::Tool
    include Loggable
    include DryRunnable

    description "Remove a file or directory at the given path"
    param :path, desc: "The relative path to remove"
    param :force, desc: "Whether to force removal and ignore errors", required: false

    def initialize(navigation_tool: nil)
      super()
      @navigation_tool = navigation_tool
    end

    def execute(path:, force: false)
      # Use navigation tool's current path if available, otherwise use process working directory
      base_path = @navigation_tool&.current_path || Dir.pwd
      full_path = File.expand_path(path, base_path)

      unless File.exist?(full_path)
        return { error: "Path not found: #{path}" }
      end

      FileUtils.rm_r(full_path, force: force)

      info "Successfully removed #{full_path}"
      { success: true, removed: path, full_path: full_path }
    rescue => e
      { error: e.message }
    end
  end
end
