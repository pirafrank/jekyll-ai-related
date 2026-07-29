# frozen_string_literal: true

require "bundler/gem_tasks"
require "rubocop/rake_task"
require "rake/testtask"

RuboCop::RakeTask.new

task :default do
  sh "rake -AT"
end

Rake::TestTask.new(:test) do |t|
  t.libs << "lib"
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

task lint: :rubocop

task :changelog do
  sh "git cliff --tag #{Gem::Specification.load("jekyll-ai-related.gemspec").version} -o CHANGELOG.md"
end

task :mkrelease do
  version = Gem::Specification.load("jekyll-ai-related.gemspec").version
  sh "git cliff --tag #{version} -o CHANGELOG.md"
  sh "git add CHANGELOG.md"
  sh "git commit -m 'chore: update CHANGELOG.md'"
  sh "git tag -s -a -m 'v#{version}' v#{version}"
  sh "git push origin #{version}"
end

task :build do
  sh "gem build jekyll-ai-related.gemspec"
end

task :publish do
  version = Gem::Specification.load("jekyll-ai-related.gemspec").version
  gem_file = "jekyll-ai-related-#{version}.gem"
  sh "gem push #{gem_file}"
end
