require "gum"

module Mildred
  class CLI
    def self.start(args)
      command_name = args[0]
      command_args = args[1..]

      if command_name.nil? || command_name == "help"
        print_help
        return
      end

      klass = commands[command_name]
      unless klass
        display_error("Unknown command: #{command_name}")
        print_help
        exit 1
      end

      klass.new(command_args).call
    rescue Mildred::Error => e
      display_error(e.message)
      exit 1
    end

    def self.commands
      @commands ||= {}
    end

    def self.register(name, klass)
      commands[name.to_s] = klass
    end

    def self.print_help
      puts Gum.style("mildred", foreground: "212", bold: true, border: :rounded, padding: "0 2")
      puts
      commands.each do |name, klass|
        label = Gum.style("  #{name}", foreground: "39", bold: true)
        desc = Gum.style(" #{klass.description}", foreground: "252")
        puts "#{label}#{desc}"
      end
      puts
    end

    def self.display_error(msg)
      puts Gum.style(
        "  ✗ #{msg}",
        foreground: "203",
        bold: true,
        border: :rounded,
        border_foreground: "203",
        padding: "0 1"
      )
    end
  end

  class Error < StandardError; end
end
