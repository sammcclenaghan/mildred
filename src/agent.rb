require "ruby_llm"
require_relative "tools/read_file"
require_relative "tools/list_files"
require_relative "loggable"

class Agent
  include Loggable

  def initialize(dry_run: false)
    @chat = RubyLLM.chat
    @chat.with_tools(Tools::ReadFile, Tools::ListFiles, )

    # Set dry run mode for all tools
    [Tools::ReadFile, Tools::ListFiles].each do |tool|
      tool.dry_run_mode = dry_run
    end
    info "Agent initialized in #{dry_run ? 'dry-run' : 'normal'} mode"
  end

  def run
    puts "Chat with the agent. Type 'exit' to ... well, exit"
    loop do
      print "> "
      user_input = STDIN.gets.chomp
      break if user_input == "exit"

      info "Processing user input: #{user_input}"
      response = @chat.ask user_input
      debug "Got response: #{response.content}"
      puts response.content
    end
  end
end
