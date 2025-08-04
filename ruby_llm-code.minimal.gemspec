# frozen_string_literal: true

require_relative "lib/ruby_llm/code/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_llm-code"
  spec.version = RubyLLM::Code::VERSION
  spec.authors = ["Carmine Paolino"]
  spec.email = ["carmine@paolino.me"]
  
  spec.summary = "AI-powered coding assistant for Ruby (coming soon)"
  spec.description = "RubyLLM Code will provide an AI-powered coding assistant. This is a placeholder release - full implementation coming soon!"
  spec.homepage = "https://github.com/crmne/ruby_llm-code"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  
  # Only include minimal files for the placeholder release
  spec.files = [
    "lib/ruby_llm-code.minimal.rb",
    "lib/ruby_llm/code/version.rb",
    "README.minimal.md",
    "LICENSE"
  ]
  
  spec.bindir = "bin"
  spec.executables = []  # No executable in minimal version
  spec.require_paths = ["lib"]
  
  # Minimal dependencies
  spec.add_dependency "ruby_llm", "~> 1.5.1"
end