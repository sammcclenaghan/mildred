require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

desc "Build and install the gem, then rebuild the container image"
task :install do
  sh "gem build mildred.gemspec"
  gem_file = Dir["mildred-*.gem"].max_by { |f| File.mtime(f) }
  sh "gem install #{gem_file} --force"
  File.delete(gem_file)
  sh "mildred build"
end

task default: :test
