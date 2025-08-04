# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/SpecFilePathFormat, RSpec/InstanceVariable

RSpec.describe RubyLLM::Code::Config do
  let(:config) { described_class.new }

  before do
    # Temporarily rename config file if it exists to avoid interference
    @config_backup = nil
    config_path = File.expand_path('~/.rubyllm/config.yml')
    if File.exist?(config_path)
      @config_backup = "#{config_path}.backup"
      FileUtils.mv(config_path, @config_backup)
    end
  end

  after do
    # Restore config file if we backed it up
    if @config_backup && File.exist?(@config_backup)
      FileUtils.mv(@config_backup, File.expand_path('~/.rubyllm/config.yml'))
    end
  end

  describe '#initialize' do
    it 'sets default values' do
      # Clear any environment variables that might affect the test
      original_model = ENV.delete('RUBYLLM_MODEL')

      config = described_class.new
      expect(config.model).to eq('claude-3-5-haiku-20241022')
      expect(config.temperature).to eq(0.7)
      expect(config.tools_enabled).to be true
      expect(config.memory_enabled).to be true
      expect(config.auto_approval).to eq([])

      # Restore original value if it existed
      ENV['RUBYLLM_MODEL'] = original_model if original_model
    end

    it 'respects RUBYLLM_MODEL environment variable' do
      # Store original value
      original_model = ENV.fetch('RUBYLLM_MODEL', nil)

      ENV['RUBYLLM_MODEL'] = 'gpt-4'
      new_config = described_class.new
      expect(new_config.model).to eq('gpt-4')

      # Restore original value
      if original_model
        ENV['RUBYLLM_MODEL'] = original_model
      else
        ENV.delete('RUBYLLM_MODEL')
      end
    end
  end

  describe '#workspace' do
    it 'returns a workspace instance' do
      expect(config.workspace).to be_a(RubyLLM::Code::Workspace)
      # The workspace root should be the configured workspace_dir
      expect(config.workspace.root).to eq(config.workspace_dir)
    end
  end

  describe '#memory' do
    it 'returns a memory instance when enabled' do
      config.memory_enabled = true
      expect(config.memory).to be_a(RubyLLM::Code::Memory)
    end

    it 'returns nil when disabled' do
      config.memory_enabled = false
      expect(config.memory).to be_nil
    end
  end

  describe '#load_file' do
    it 'loads configuration from YAML file' do
      config_file = File.join(@temp_dir, 'test_config.yml')
      File.write(config_file, {
        'model' => 'test-model',
        'temperature' => 0.5,
        'tools_enabled' => false
      }.to_yaml)

      config.load_file(config_file)

      expect(config.model).to eq('test-model')
      expect(config.temperature).to eq(0.5)
      expect(config.tools_enabled).to be false
    end

    it 'handles missing files gracefully' do
      expect { config.load_file('nonexistent.yml') }.not_to raise_error
    end
  end

  describe '#save' do
    it 'saves configuration to file' do
      config.model = 'custom-model'
      config.temperature = 0.9
      config.save

      saved_config = YAML.load_file(RubyLLM::Code::Config::CONFIG_FILE)
      expect(saved_config['model']).to eq('custom-model')
      expect(saved_config['temperature']).to eq(0.9)
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat, RSpec/InstanceVariable
