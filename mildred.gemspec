# frozen_string_literal: true

require_relative "lib/mildred/version"

Gem::Specification.new do |spec|
  spec.name = "mildred"
  spec.version = Mildred::VERSION
  spec.authors = ["Sam McClenaghan"]
  spec.email = ["sam@aream.ca"]

  spec.summary = "AI-powered file organizer. Describe what you want, and Mildred does it."
  spec.description = "Be lazier. A little more active maid, let mildred take care of you. Inspired by Maid, describe tasks in plain english. Runs securely in Apple containers"
  spec.homepage = "https://github.com/sammcclenaghan/mildred"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sammcclenaghan/mildred"
  spec.metadata["changelog_uri"] = "https://github.com/sammcclenaghan/mildred/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby_llm", "~> 1.9"
  spec.add_dependency "activesupport", "~> 8.0"
  spec.add_dependency "gum", "~> 0.3"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
