# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/InstanceVariable, RSpec/SpecFilePathFormat

RSpec.describe RubyLLM::Code::Tools::WriteFile do
  let(:tool) { described_class.new(test_config) }

  describe '#execute' do
    it 'writes content to a new file' do
      result = tool.execute(file_path: 'new_file.txt', content: 'Hello, world!')

      expect(result).to include('created successfully')
      expect(File.read(File.join(@temp_dir, 'new_file.txt'))).to eq('Hello, world!')
    end

    it 'overwrites existing files' do
      existing = create_test_file('existing.txt', 'old content')

      result = tool.execute(file_path: existing, content: 'new content')

      expect(result).to include('written successfully')
      expect(File.read(existing)).to eq('new content')
    end

    it 'creates parent directories' do
      result = tool.execute(file_path: 'deep/nested/file.txt', content: 'test')

      expect(result).to include('successfully')
      expect(result).not_to include('Error:')
      expect(File.exist?(File.join(@temp_dir, 'deep/nested/file.txt'))).to be true
    end

    it 'validates workspace boundaries' do
      result = tool.execute(file_path: '/tmp/outside.txt', content: 'test')
      expect(result).to include('Error:')
      expect(result).to include('Path outside workspace')
    end

    it 'handles write errors gracefully' do
      allow(File).to receive(:write).and_raise(Errno::EACCES)

      result = tool.execute(file_path: 'file.txt', content: 'test')

      expect(result).to include('Error: Failed to write file')
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/SpecFilePathFormat
