# frozen_string_literal: true

require 'bundler/setup'
require 'ruby_llm-code'
require 'tempfile'
require 'fileutils'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed

  # Helper to create temporary test directories
  config.around do |example|
    Dir.mktmpdir do |dir|
      @temp_dir = File.expand_path(dir)
      Dir.chdir(@temp_dir) do
        example.run
      end
    end
  end

  # Stub RubyLLM for testing
  config.before do
    # rubocop:disable RSpec/VerifiedDoubles
    allow(RubyLLM).to receive(:chat).and_return(double('chat',
                                                       ask: double('response', content: 'Test response'),
                                                       messages: [],
                                                       model: double('model', id: 'test-model')))
  end
  # rubocop:enable RSpec/VerifiedDoubles
end

# Test helpers
module TestHelpers
  def create_test_file(path, content = 'test content')
    full_path = File.join(@temp_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def test_config
    config = RubyLLM::Code::Config.new
    config.workspace_dir = File.expand_path(@temp_dir)
    config
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
