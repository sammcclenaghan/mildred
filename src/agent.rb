require "ruby_llm"

require_relative "tools/read_file"
require_relative "tools/list_files"
class Agent
  def initialize
    @chat = RubyLLM.chat(model: "granite4:latest", provider: :openai, assume_model_exists: true)
    @chat.with_instructions "You are a file organizer who will be given tasks and you will use tool calls to implement them, be super concise, we need almost no output from you"
    @chat.with_tools(Tools::ReadFile, Tools::ListFiles)
      .on_tool_call do |tool_call|
        puts "Calling tool: #{tool_call.name}"
        puts "Arguments: #{tool_call.arguments}"
      end
      .on_tool_result do |result|
        puts "Tool returned: #{result}"
      end
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
