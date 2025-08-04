# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Full workflow integration' do # rubocop:disable RSpec/DescribeClass
  let(:config) { test_config }

  it 'performs a complete file operation workflow' do
    # Create test files
    create_test_file('src/app.rb', "class App\n  def hello\n    'world'\n  end\nend")
    create_test_file('test/app_test.rb',
                     "require 'app'\n\nclass AppTest\n  def test_hello\n    assert_equal 'world', App.new.hello\n  end\nend") # rubocop:disable Layout/LineLength

    # Initialize tools
    read_tool = RubyLLM::Code::Tools::ReadFile.new(config)
    write_tool = RubyLLM::Code::Tools::WriteFile.new(config)
    grep_tool = RubyLLM::Code::Tools::Grep.new(config)
    shell_tool = RubyLLM::Code::Tools::Shell.new(config)

    # Search for class definitions
    grep_result = grep_tool.execute(pattern: 'class \\w+')
    expect(grep_result).to include('src/app.rb')
    expect(grep_result).to include('test/app_test.rb')

    # Read the main file
    read_result = read_tool.execute(file_path: 'src/app.rb')
    expect(read_result).to include('class App')

    # Modify the file
    new_content = read_result.gsub("'world'", "'Hello, RubyLLM!'")
    write_result = write_tool.execute(file_path: 'src/app.rb', content: new_content)
    expect(write_result).to include('successfully')

    # Verify the change
    verify_result = shell_tool.execute(command: "grep 'Hello, RubyLLM!' src/app.rb")
    expect(verify_result).to include('Hello, RubyLLM!')
  end

  it 'handles memory persistence across sessions' do
    memory1 = RubyLLM::Code::Memory.new
    memory1.add('project_name', 'TestProject')
    memory1.add('preferred_style', 'functional')

    # Simulate new session
    memory2 = RubyLLM::Code::Memory.new
    expect(memory2.get('project_name')).to eq('TestProject')
    expect(memory2.get('preferred_style')).to eq('functional')

    # Clean up
    memory2.clear
  end

  it 'respects workspace boundaries' do
    read_tool = RubyLLM::Code::Tools::ReadFile.new(config)
    write_tool = RubyLLM::Code::Tools::WriteFile.new(config)

    # Should fail for paths outside workspace
    expect { read_tool.execute(file_path: '/etc/passwd') }.to raise_error(/workspace/)
    result = write_tool.execute(file_path: '/tmp/test.txt', content: 'test')
    expect(result).to include('Error:')
    expect(result).to include('Path outside workspace')

    # Should work for paths within workspace
    result = write_tool.execute(file_path: 'allowed.txt', content: 'safe content')
    expect(result).to include('successfully')
  end

  it 'handles complex grep patterns with context' do
    # Create a Ruby file with methods
    ruby_content = <<~RUBY
      class Calculator
        def add(a, b)
          a + b
        end
      #{'  '}
        def subtract(a, b)
          a - b
        end
      #{'  '}
        def multiply(a, b)
          a * b
        end
      end
    RUBY

    create_test_file('calculator.rb', ruby_content)

    grep_tool = RubyLLM::Code::Tools::Grep.new(config)

    # Search for method definitions with context
    result = grep_tool.execute(
      pattern: 'def \\w+\\(.*\\)',
      glob: '*.rb',
      output_mode: 'content',
      '-C': 1
    )

    expect(result).to include('def add')
    expect(result).to include('def subtract')
    expect(result).to include('def multiply')

    # Check context includes method body
    expect(result).to include('a + b')
  end
end
