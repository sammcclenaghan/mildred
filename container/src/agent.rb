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
    @chat.with_instructions <<~PROMPT
      You are a file organizer. You operate on the current working directory.

      RULES:
      - ALWAYS call list_files before doing anything else so you know what files actually exist.
      - ONLY reference file names that were returned by list_files or read_file. NEVER invent or guess file names.
      - Use move_file to move files and create_directory to create folders.
      - Use delete_file to remove files when asked.
      - Be concise. Report what you did in a short list, nothing else.
      - If a task cannot be completed (e.g. no matching files), say so briefly.
    PROMPT
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

      begin
        response = @chat.ask(task)
        content = response.content
        if content.nil? || content.strip.empty?
          # Model ended on a tool call with no text summary — ask it to summarize
          response = @chat.ask("What did you just do? Summarize briefly.")
          content = response.content
        end
        $stdout.puts content unless content.nil? || content.strip.empty?
      rescue => e
        $stderr.puts "Error processing task: #{e.message}"
        $stdout.puts "Error: #{e.message}"
      end
    end
  end
end
