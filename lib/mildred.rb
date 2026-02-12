require_relative "mildred/cli"
require_relative "mildred/command"
require_relative "mildred/commands/build"
require_relative "mildred/commands/clean"
require_relative "mildred/commands/init"

Mildred::CLI.register "build", Mildred::Commands::Build
Mildred::CLI.register "clean", Mildred::Commands::Clean
Mildred::CLI.register "init",  Mildred::Commands::Init
