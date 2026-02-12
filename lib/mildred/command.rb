module Mildred
  class Command
    def self.desc(description)
      @description = description
    end

    def self.description
      @description || ""
    end

    def initialize(args = [])
      @args = args
    end

    def call
      raise NotImplementedError
    end

    private

    def display_header(text)
      puts Gum.style(text, foreground: "212", bold: true, border: :rounded, padding: "0 1")
    end

    def display_success(text)
      puts Gum.style("  ✓ #{text}", foreground: "76", bold: true)
    end

    def display_info(text)
      puts Gum.style("  #{text}", foreground: "252", italic: true)
    end

    def display_step(text)
      puts Gum.style("  → #{text}", foreground: "39")
    end
  end
end
