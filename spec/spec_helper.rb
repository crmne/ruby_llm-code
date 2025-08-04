# frozen_string_literal: true

require "bundler/setup"
require "rubyllm_cli"
require "tempfile"
require "fileutils"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
  
  # Helper to create temporary test directories
  config.around(:each) do |example|
    Dir.mktmpdir do |dir|
      @temp_dir = dir
      Dir.chdir(dir) do
        example.run
      end
    end
  end
  
  # Stub RubyLLM for testing
  config.before(:each) do
    allow(RubyLLM).to receive(:chat).and_return(double("chat", 
      ask: double("response", content: "Test response"),
      messages: [],
      model: double("model", id: "test-model")
    ))
  end
end

# Test helpers
module TestHelpers
  def create_test_file(path, content = "test content")
    full_path = File.join(@temp_dir, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end
  
  def test_config
    config = RubyLLMCLI::Config.new
    config.workspace_dir = @temp_dir
    config
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end