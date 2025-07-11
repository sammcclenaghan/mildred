require "ruby_llm"
require_relative "tools/read_file"
require_relative "tools/list_files"
require_relative "tools/remove_file"
require_relative "tools/navigate_directory"
require_relative "tools/copy_file"
require_relative "tools/move_file"
require_relative "tools/make_directory"
require_relative "tools/disk_space"
require_relative "loggable"

class Agent
  include Loggable

  def initialize(dry_run: false, root_path: Dir.pwd)
    @chat = RubyLLM.chat
    @root_path = File.expand_path(root_path)
    @current_path = @root_path
    @start_path = @root_path
    info "Initializing agent with root_path: #{@root_path}"
    info "Current working directory: #{@current_path}"

    nav_tool = Tools::NavigateDirectory.new(initial_path: @current_path)
    list_tool = Tools::ListFiles.new(navigation_tool: nav_tool)
    remove_tool = Tools::RemoveFile.new(navigation_tool: nav_tool)
    read_tool = Tools::ReadFile.new(navigation_tool: nav_tool)
    copy_tool = Tools::CopyFile.new(navigation_tool: nav_tool)
    move_tool = Tools::MoveFile.new(navigation_tool: nav_tool)
    make_dir_tool = Tools::MakeDirectory.new(navigation_tool: nav_tool)

    @chat.with_tools(
      read_tool,
      remove_tool,
      nav_tool,
      list_tool,
      copy_tool,
      move_tool,
      make_dir_tool,
      Tools::DiskSpace
    )

    # Set dry run mode for all tools
    [
      read_tool.class,
      list_tool.class,
      remove_tool.class,
      nav_tool.class,
      copy_tool.class,
      move_tool.class,
      make_dir_tool.class,
      Tools::DiskSpace
    ].each do |tool|
      tool.dry_run_mode = dry_run
    end

    setup_safety_boundaries
    info "Agent initialized in #{dry_run ? 'dry-run' : 'normal'} mode at #{@root_path}"
  end

  def ask(input)
    info "Processing input: #{input}"
    response = @chat.ask(input)
    debug "Got response: #{response.content} (current_path: #{@current_path})"
    response
  end

  def run
    puts "Chat with the agent. Type 'exit' to ... well, exit"
    loop do
      print "> "
      user_input = STDIN.gets.chomp
      break if user_input == "exit"

      response = ask(user_input)
      puts response.content
    end
  end

  private

  def setup_safety_boundaries
    # Add safety context to the AI
    safety_prompt = <<~PROMPT
      You are a file system navigator with the following safety rules:
      1. Never navigate above the root directory: #{@root_path}
      2. Always verify paths before operations
      3. Never modify system or hidden files
      4. Always confirm before destructive operations when in dry run mode
      5. Keep track of your current location

      Current location: #{@current_path}
    PROMPT

    @chat.with_instructions safety_prompt
  end

  def validate_path(path)
    expanded_path = File.expand_path(path, @current_path)
    debug "Validating path: #{path} -> #{expanded_path} (root: #{@root_path})"
    if expanded_path.start_with?(@root_path) || expanded_path.start_with?(@start_path)
      expanded_path
    else
      raise "Access denied: Cannot access paths outside of #{@root_path} or #{@start_path}"
    end
  end

  def update_current_path(new_path)
    @current_path = validate_path(new_path)
    debug "Updated current path to: #{@current_path}"
  end
end
