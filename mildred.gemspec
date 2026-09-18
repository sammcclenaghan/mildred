Gem::Specification.new do |s|
  s.name        = "mildred"
  s.version     = "0.1.0"
  s.summary     = "AI file organizer that runs in a sandboxed Apple Container"
  s.description = "Mildred reads a YAML config, spins up an Apple Container, and uses a local LLM to organize your files."
  s.authors     = ["Sam McClenaghan"]
  s.homepage    = "https://github.com/sammcclenaghan/mildred"
  s.license     = "MIT"

  s.files       = Dir["lib/**/*", "bin/*", "container/**/*"]
  s.executables = ["mildred"]

  s.required_ruby_version = ">= 3.0"

  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "ruby_llm", "~> 1.11"
  s.add_development_dependency "vcr", "~> 6.0"
  s.add_development_dependency "webmock", "~> 3.0"
end
