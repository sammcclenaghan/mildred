# frozen_string_literal: true

module DryRunnable
  def self.included(base)
    base.extend(ClassMethods)
    base.prepend(ExecutionWrapper)
  end

  module ClassMethods
    def dry_run_mode=(value)
      @dry_run_mode = value
    end

    def dry_run_mode?
      @dry_run_mode || false
    end
  end

  module ExecutionWrapper
    def execute(*args, **kwargs)
      return dry_run_execute(*args, **kwargs) if self.class.dry_run_mode?
      super
    end

    private

    def dry_run_execute(*args, **kwargs)
      info "[DRY RUN] Would execute #{self.class.name}:"
      info "[DRY RUN] Arguments: #{args.inspect}" unless args.empty?
      info "[DRY RUN] Keyword Arguments: #{kwargs.inspect}" unless kwargs.empty?
      { dry_run: true, tool: self.class.name, args: args, kwargs: kwargs }
    end
  end
end
