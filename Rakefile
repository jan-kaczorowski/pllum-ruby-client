require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--exclude-pattern 'spec/integration/**/*_spec.rb'"
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ["--display-cop-names"]
end

desc "Run all tests, including integration tests"
task :spec_all do
  puts "Running all tests including integration tests"
  system("bundle exec rspec")
end

desc "Run integration tests only"
task :spec_integration do
  puts "Running integration tests"
  system("bundle exec rspec spec/integration --tag integration")
end

desc "Run linting with RuboCop"
task :lint => :rubocop

desc "Run all tests and linting"
task :default => [:spec, :lint]