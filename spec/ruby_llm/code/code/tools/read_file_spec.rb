# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/SpecFilePathFormat

RSpec.describe RubyLLM::Code::Tools::ReadFile do
  let(:tool) { described_class.new(test_config) }

  describe '#execute' do
    it 'reads file content' do
      file_path = create_test_file('test.txt', 'Hello, world!')

      result = tool.execute(file_path: file_path)

      expect(result).to include('Hello, world!')
    end

    it 'handles relative paths' do
      create_test_file('subdir/test.txt', 'Content')

      result = tool.execute(file_path: 'subdir/test.txt')

      expect(result).to include('Content')
    end

    it 'returns error for non-existent files' do
      result = tool.execute(file_path: 'missing.txt')

      expect(result).to include('Error: File not found')
    end

    it 'respects offset and limit parameters' do
      content = (1..10).map { |i| "Line #{i}" }.join("\n")
      create_test_file('lines.txt', content)

      result = tool.execute(file_path: 'lines.txt', offset: 3, limit: 2)

      expect(result).to include('Line 3')
      expect(result).to include('Line 4')
      expect(result).not_to include('Line 1')
      expect(result).not_to include('Line 5')
    end

    it 'handles binary files' do
      binary_file = create_test_file('binary.dat', "\x00\x01\x02\x03")

      result = tool.execute(file_path: binary_file)

      expect(result).to include('[Binary file')
    end

    it 'truncates very large files' do
      large_content = 'x' * 60_000
      create_test_file('large.txt', large_content)

      result = tool.execute(file_path: 'large.txt')

      expect(result).to include('x')
      expect(result.length).to be < 55_000
    end

    it 'validates workspace boundaries' do
      expect do
        tool.execute(file_path: '/etc/passwd')
      end.to raise_error(/Path outside workspace/)
    end
  end

  describe 'tool metadata' do
    it 'has required description' do
      expect(tool.class.description).to include('Reads a file from the local filesystem')
    end

    it 'has required parameters' do
      # The tool has the required parameters defined in its DSL
      expect(tool.class.instance_methods).to include(:execute)
      expect(tool.method(:execute).parameters).to include(%i[keyreq file_path])
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
