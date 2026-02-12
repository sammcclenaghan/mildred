require "ruby_llm"

require_relative "tools/read_file"
require_relative "tools/list_files"
require_relative "tools/move_file"
require_relative "tools/create_directory"

class Agent
  def initialize
    workspace = ENV.fetch("WORKSPACE", "/workspace")
    Dir.chdir(workspace)

    @tool_log = []

    @chat = RubyLLM.chat(model: ENV.fetch("MILDRED_MODEL", "qwen2.5:7b"), provider: :openai, assume_model_exists: true)
    @chat.with_instructions <<~PROMPT
      You are a file organizer. You operate on the current working directory.

      RULES:
      - ALWAYS call list_files before doing anything else so you know what files actually exist.
      - ONLY reference file names that were returned by list_files or read_file. NEVER invent or guess file names.
      - Use move_file to move files and create_directory to create folders.
      - Use delete_file to remove files when asked.
      - After completing a task, ALWAYS respond with a short text summary of what you did.
      - If a task cannot be completed (e.g. no matching files), say so briefly.
    PROMPT
    @chat.with_tools(Tools::ReadFile, Tools::ListFiles, Tools::MoveFile, Tools::CreateDirectory)
      .on_tool_call do |tool_call|
        $stderr.puts "Calling tool: #{tool_call.name}"
        @tool_log << { tool: tool_call.name, args: tool_call.arguments }
      end
      .on_tool_result do |result|
        @tool_log.last[:result] = result.to_s if @tool_log.last
      end
  end

  def run
    $stdout.sync = true
    $stderr.sync = true

    while (line = $stdin.gets)
      task = line.strip
      next if task.empty?

      @tool_log.clear

      begin
        response = @chat.ask(task)
        content = response.content

        if (content.nil? || content.strip.empty?) && @tool_log.empty?
          $stdout.puts "Warning: Model returned no response and made no tool calls. Try a different model (e.g. qwen3, llama3.2)."
          next
        end

        if (content.nil? || content.strip.empty?) && !@tool_log.empty?
          content = summarize_tool_log
        end

        $stdout.puts content unless content.nil? || content.strip.empty?
      rescue => e
        $stdout.puts "Error: #{e.message}"
      end
    end
  end

  private

  def summarize_tool_log
    actions = @tool_log.select { |entry| %w[move_file delete_file create_directory].include?(entry[:tool]) }

    if actions.empty?
      list_entry = @tool_log.find { |e| e[:tool] == "list_files" }
      return list_entry ? list_entry[:result].to_s : "No actions taken."
    end

    actions.map { |entry| entry[:result].to_s }.join("\n")
  end
end
