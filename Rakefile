desc "Build gem, install it, and rebuild the container image"
task :install do
  sh "gem build mildred.gemspec"
  gem_file = Dir["mildred-*.gem"].max_by { |f| File.mtime(f) }
  sh "gem install #{gem_file}"
  File.delete(gem_file)
  sh "mildred build"
end

task default: :install
