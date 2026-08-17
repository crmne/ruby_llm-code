# frozen_string_literal: true

require_relative 'lib/ruby_llm/code/version'

Gem::Specification.new do |spec|
  spec.name = 'ruby_llm-code'
  spec.version = RubyLLM::Code::VERSION
  spec.authors = ['Carmine Paolino']
  spec.email = ['carmine@paolino.me']

  spec.summary = 'A minimal coding agent for your terminal, built on RubyLLM'
  spec.description = 'RubyLLM Code is a small coding agent for the terminal: read, write, and run code with any ' \
                     'model RubyLLM supports, and put two models on the same task with /collab so they explore, ' \
                     'argue, and agree before touching your files.'
  spec.homepage = 'https://github.com/crmne/ruby_llm-code'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir[
    'lib/**/*',
    'bin/*',
    'README.md',
    'LICENSE'
  ]

  spec.bindir = 'bin'
  spec.executables = ['rubyllm']
  spec.require_paths = ['lib']

  # RubyLLM 2.0 for the agentic loop, tool approval, and the usage ledger. It is
  # unreleased, so the Gemfile tracks trunk and this stays unpinned until 2.0 ships.
  spec.add_dependency 'ruby_llm'
  # Charm, ported to Ruby by Marco Roth: terminal styling and markdown.
  spec.add_dependency 'glamour', '~> 0.2'
  spec.add_dependency 'lipgloss', '~> 0.2'
  # Fibers, so collaborating agents run their turns at the same time.
  spec.add_dependency 'async', '~> 2.23'
  # Line editing for the prompt.
  spec.add_dependency 'reline', '>= 0.5'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end
