Gem::Specification.new do |s|
  s.name        = "mildred"
  s.version     = "0.1.0"
  s.summary     = "AI file organizer that runs in a sandboxed Apple Container"
  s.description = "Mildred reads a YAML config, spins up an Apple Container, and uses an LLM to organize your files safely."
  s.authors     = ["Sam McClenaghan"]
  s.homepage    = "https://github.com/sammcclenaghan/mildred"
  s.license     = "MIT"

  s.files       = Dir["lib/**/*", "bin/*", "container/**/*"]
  s.executables = ["mildred"]

  s.required_ruby_version = ">= 3.0"
end
