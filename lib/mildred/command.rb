module Mildred
  class Command
    def self.desc(description)
      @description = description
    end

    def self.description
      @description || ""
    end

    def self.option(name, alias: nil, desc: "", default: nil, type: :boolean)
      @options ||= {}
      @options[name] = { alias: binding.local_variable_get(:alias), desc: desc, default: default, type: type }
    end

    def self.defined_options
      @options || {}
    end

    def initialize(args = [])
      @args = args
      @options = parse_options(args)
    end

    def call
      raise NotImplementedError
    end

    private

    def parse_options(args)
      opts = {}
      defined = self.class.defined_options

      defined.each do |name, config|
        flag = "--#{name.to_s.tr("_", "-")}"
        short = config[:alias]

        case config[:type]
        when :boolean
          opts[name] = args.delete(flag) || (short && args.delete(short)) ? true : (config[:default] || false)
        when :string
          idx = args.index(flag) || (short && args.index(short))
          if idx && args[idx + 1]
            args.delete_at(idx)
            opts[name] = args.delete_at(idx)
          else
            opts[name] = config[:default]
          end
        end
      end

      opts
    end

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
