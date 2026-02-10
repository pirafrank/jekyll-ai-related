# frozen_string_literal: true

require_relative "lib/jekyll/embeddings-generator/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-ai-related"
  spec.version = Jekyll::EmbeddingsGenerator::VERSION
  spec.authors = ["Francesco Pira"]
  spec.email = ["dev@fpira.com"]

  spec.summary = "Jekyll plugin to generate embeddings for posts and find related content"
  spec.description = "A Jekyll plugin that uses OpenAI embeddings to analyze posts and find related content"
  spec.homepage = "https://github.com/pirafrank/jekyll-ai-related"

  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r!^bin/!) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/pirafrank/jekyll-ai-related/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/pirafrank/jekyll-ai-related/issues"

  spec.add_runtime_dependency "jekyll", ">= 3.7", "< 5.0"

  spec.add_dependency "httparty", "~> 0.22"
  spec.add_dependency "json", "~> 2.7"

  spec.add_development_dependency "bundler", "~> 2.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop-jekyll", "~> 0.14"
end
