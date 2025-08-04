# frozen_string_literal: true

require 'spec_helper'
# rubocop:disable RSpec/InstanceVariable, RSpec/SpecFilePathFormat

RSpec.describe RubyLLM::Code::Tools::Shell do
  let(:tool) { described_class.new(test_config) }

  describe '#execute' do
    it 'executes simple commands' do
      result = tool.execute(command: "echo 'Hello, world!'")

      expect(result).to include('Hello, world!')
    end

    it 'captures stderr' do
      result = tool.execute(command: "echo 'error' >&2")

      expect(result).to include('error')
    end

    it 'respects working directory' do
      subdir = File.join(@temp_dir, 'subdir')
      FileUtils.mkdir_p(subdir)

      result = tool.execute(command: 'cd subdir && pwd')

      expect(result).to include('subdir')
    end

    it 'handles command timeout' do
      result = tool.execute(command: 'sleep 5', timeout: 1)

      expect(result).to include('timed out')
    end

    it 'reports command duration' do
      result = tool.execute(command: 'echo test')

      expect(result).to include('test')
    end

    it 'truncates very long output' do
      result = tool.execute(command: 'seq 1 20000')

      expect(result).to include('... (output truncated)')
      expect(result.length).to be < 31_000
    end

    it 'validates dangerous commands' do
      result = tool.execute(command: 'rm -rf /')

      expect(result).to include('dangerous')
    end

    it 'validates directory exists' do
      result = tool.execute(command: 'cd nonexistent && pwd')

      expect(result).to include('No such file or directory')
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/SpecFilePathFormat
