require "ruby_llm"
require_relative 'tools/read_file'
require_relative 'tools/list_files'

class Agent
  def initialize
    @chat = RubyLLM.chat
    @chat.with_tools(Tools::ReadFile, Tools::ListFiles)
  end

  def run
    puts "Chat with the agent. Type 'exit' to ... well, exit"
    loop do
      print "> "
      user_input = gets.chomp
      break if user_input == "exit"

      response = @chat.ask user_input
      puts response.content
    end
  end
end
