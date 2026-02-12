require "ruby_llm"

require_relative "tools/read_file"
require_relative "tools/list_files"
require_relative "tools/move_file"
require_relative "tools/create_directory"

class Agent
  def initialize
    workspace = ENV.fetch("WORKSPACE", "/workspace")
    Dir.chdir(workspace)
    $stderr.puts "Working in: #{workspace}"

    @chat = RubyLLM.chat(model: ENV.fetch("MILDRED_MODEL", "granite4:latest"), provider: :openai, assume_model_exists: true)
    @chat.with_instructions "You are a file organizer who will be given tasks and you will use tool calls to implement them, be super concise, we need almost no output from you"
    @chat.with_tools(Tools::ReadFile, Tools::ListFiles, Tools::MoveFile, Tools::CreateDirectory)
      .on_tool_call do |tool_call|
        $stderr.puts "Calling tool: #{tool_call.name}"
        $stderr.puts "Arguments: #{tool_call.arguments}"
      end
      .on_tool_result do |result|
        $stderr.puts "Tool returned: #{result}"
      end
  end

  def run
    $stdout.sync = true
    $stderr.sync = true

    while (line = $stdin.gets)
      task = line.strip
      next if task.empty?

      response = @chat.ask(task)
      $stdout.puts response.content
    end
  end
end
