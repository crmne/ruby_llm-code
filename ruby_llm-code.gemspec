# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "ruby_llm-code"
  spec.version = "1.0.0"
  spec.authors = ["Carmine Paolino"]
  spec.email = ["carmine@paolino.me"]
  
  spec.summary = "A powerful coding assistant powered by RubyLLM"
  spec.description = "RubyLLM Code provides an AI-powered coding assistant with file operations, shell execution, web search, and MCP support, optimized for software development workflows."
  spec.homepage = "https://github.com/crmne/ruby_llm-code"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"
  
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  
  spec.files = Dir[
    "lib/**/*",
    "bin/*",
    "README.md",
    "LICENSE",
    "Gemfile"
  ]
  
  spec.bindir = "bin"
  spec.executables = ["rubyllm"]
  spec.require_paths = ["lib"]
  
  spec.add_dependency "ruby_llm", "~> 1.0"
  spec.add_dependency "ruby_llm-mcp", "~> 0.1"
  spec.add_dependency "zeitwerk", "~> 2.6"
  
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "standard", "~> 1.31"
end