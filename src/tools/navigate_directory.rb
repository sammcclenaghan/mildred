require "ruby_llm/tool"
require_relative '../loggable'
require_relative '../dry_runnable'

module Tools
  class NavigateDirectory < RubyLLM::Tool
    include Loggable
    include DryRunnable

    description "Navigate to a directory and remember the current path"
    param :path, desc: "The relative or absolute path to navigate to"

    def initialize(initial_path: nil)
      super()
      @current_path = initial_path || ENV['HOME']
      @root_path = initial_path || ENV['HOME']
      info "NavigateDirectory initialized at: #{@current_path}"
    end

    def execute(path:)
      target_path = resolve_path(path)

      unless File.directory?(target_path)
        return { error: "Not a directory or doesn't exist: #{path}" }
      end

      unless safe_path?(target_path)
        return { error: "Access denied: Cannot navigate outside of #{@root_path}" }
      end

      previous_path = @current_path
      @current_path = target_path

      # Instead of using Dir.chdir, just update our path
      info "Changed directory from #{previous_path} to #{@current_path}"
      {
        success: true,
        previous: previous_path,
        current: @current_path,
        files: list_current_directory
      }
    rescue => e
      error "Navigation failed: #{e.message}"
      { error: e.message }
    end

    def current_path
      @current_path
    end

    private

    def resolve_path(path)
      case path.downcase
      when "~", "home"
        ENV['HOME']
      when ".."
        File.expand_path("..", @current_path)
      else
        File.expand_path(path, @current_path)
      end
    end

    def safe_path?(path)
      File.expand_path(path).start_with?(@root_path)
    end

    def list_current_directory
      Dir.entries(@current_path)
         .reject { |f| f.start_with?('.') }
         .map { |f| File.directory?(File.join(@current_path, f)) ? "#{f}/" : f }
    end
  end
end
