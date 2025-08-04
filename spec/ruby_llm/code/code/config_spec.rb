# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/SpecFilePathFormat, RSpec/InstanceVariable

RSpec.describe RubyLLM::Code::Config do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      expect(config.model).to eq('claude-3-5-haiku-20241022')
      expect(config.temperature).to eq(0.7)
      expect(config.tools_enabled).to be true
      expect(config.memory_enabled).to be true
      expect(config.auto_approval).to eq([])
    end

    it 'respects RUBYLLM_MODEL environment variable' do
      ENV['RUBYLLM_MODEL'] = 'gpt-4'
      new_config = described_class.new
      expect(new_config.model).to eq('gpt-4')
      ENV.delete('RUBYLLM_MODEL')
    end
  end

  describe '#workspace' do
    it 'returns a workspace instance' do
      expect(config.workspace).to be_a(RubyLLM::Code::Workspace)
      expect(config.workspace.root).to eq(Dir.pwd)
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
