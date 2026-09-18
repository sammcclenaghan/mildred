require "ruby_llm"
require_relative "tools"

class Agent
  TOOLS = [ListFiles, ReadFile, MoveFile].freeze

  def initialize(workspace:, model:, out: $stdout)
    @workspace = workspace
    @model = model
    @out = out
  end

  def run(tasks)
    Dir.chdir(@workspace) do
      chat = build_chat(Dir.children(".").sort)

      tasks.each do |task|
        @out.puts "\n#{task}"
        reply = chat.ask(task).content.to_s.strip
        @out.puts reply.empty? ? "  (no summary from model)" : reply.gsub(/^/, "  ")
      rescue => e
        @out.puts "  Error: #{e.message}"
      end
    end
  end

  private

  def build_chat(dirs)
    RubyLLM.chat(model: @model, provider: :openai, assume_model_exists: true)
      .with_temperature(0)
      .with_instructions(prompt(dirs))
      .with_tools(*TOOLS)
      .on_tool_call { |call| @out.puts "  → #{call.name} #{format_args(call.arguments)}" }
  end

  def prompt(dirs)
    <<~PROMPT
      You organize files. You can see these folders:
      #{dirs.map { |d| "  - #{d}/" }.join("\n")}

      Rules:
      - Call list_files on a folder before touching it. Only use file names it returned. Never guess names.
      - Every path starts with one of the folders above, e.g. move_file("#{dirs.first}/a.pdf", "#{dirs.last}/a.pdf").
      - When done, reply with one or two sentences saying what you did, or why nothing could be done.
    PROMPT
  end

  def format_args(args)
    args.transform_keys(&:to_s).values_at("path", "source", "destination").compact.join(" ")
  end
end

if __FILE__ == $PROGRAM_NAME
  $stdout.sync = true

  RubyLLM.configure do |c|
    c.openai_api_base = ENV.fetch("OLLAMA_API_BASE")
    c.openai_api_key = "ollama"
    c.openai_use_system_role = true
  end

  Agent.new(workspace: "/workspace", model: ENV.fetch("MILDRED_MODEL")).run(ARGV)
end
