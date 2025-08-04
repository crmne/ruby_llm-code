# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "rubyllm_cli"
  spec.version = "1.0.0"
  spec.authors = ["RubyLLM CLI Contributors"]
  spec.email = ["hello@rubyllm.com"]
  
  spec.summary = "A powerful CLI for AI interactions using RubyLLM"
  spec.description = "RubyLLM CLI provides a complete command-line interface for AI conversations with file operations, shell execution, web search, and MCP support."
  spec.homepage = "https://github.com/yourusername/rubyllm-cli"
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