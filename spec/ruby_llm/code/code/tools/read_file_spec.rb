# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/SpecFilePathFormat

RSpec.describe RubyLLM::Code::Tools::ReadFile do
  let(:tool) { described_class.new(test_config) }

  describe '#execute' do
    it 'reads file content' do
      file_path = create_test_file('test.txt', 'Hello, world!')

      result = tool.execute(path: file_path)

      expect(result[:content]).to eq('Hello, world!')
      expect(result[:lines]).to eq(1)
      expect(result[:error]).to be_nil
    end

    it 'handles relative paths' do
      create_test_file('subdir/test.txt', 'Content')

      result = tool.execute(path: 'subdir/test.txt')

      expect(result[:content]).to eq('Content')
    end

    it 'returns error for non-existent files' do
      result = tool.execute(path: 'missing.txt')

      expect(result[:error]).to include('File not found')
    end

    it 'respects offset and limit parameters' do
      content = (1..10).map { |i| "Line #{i}" }.join("\n")
      create_test_file('lines.txt', content)

      result = tool.execute(path: 'lines.txt', offset: 3, limit: 2)

      expect(result[:content]).to eq("Line 3\nLine 4\n")
    end

    it 'handles binary files' do
      binary_file = create_test_file('binary.dat', "\x00\x01\x02\x03")

      result = tool.execute(path: binary_file)

      expect(result[:content]).to include('[Binary file')
    end

    it 'truncates very large files' do
      large_content = 'x' * 60_000
      create_test_file('large.txt', large_content)

      result = tool.execute(path: 'large.txt')

      expect(result[:content]).to include('... (output truncated)')
      expect(result[:content].length).to be < 55_000
    end

    it 'validates workspace boundaries' do
      expect do
        tool.execute(path: '/etc/passwd')
      end.to raise_error(/must be within workspace/)
    end
  end

  describe 'tool metadata' do
    it 'has required description' do
      expect(tool.class.description).to include('Reads and returns the content')
    end

    it 'has required parameters' do
      params = tool.class.params
      expect(params).to have_key(:path)
      expect(params[:path][:required]).to be true
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
