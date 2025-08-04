# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Full workflow integration" do
  let(:config) { test_config }
  
  it "performs a complete file operation workflow" do
    # Create test files
    create_test_file("src/app.rb", "class App\n  def hello\n    'world'\n  end\nend")
    create_test_file("test/app_test.rb", "require 'app'\n\nclass AppTest\n  def test_hello\n    assert_equal 'world', App.new.hello\n  end\nend")
    
    # Initialize tools
    read_tool = RubyLLM::Code::Tools::ReadFile.new(config)
    write_tool = RubyLLM::Code::Tools::WriteFile.new(config)
    grep_tool = RubyLLM::Code::Tools::Grep.new(config)
    shell_tool = RubyLLM::Code::Tools::Shell.new(config)
    
    # Search for class definitions
    grep_result = grep_tool.execute(pattern: "class \\w+")
    expect(grep_result[:total_matches]).to eq(2)
    
    # Read the main file
    read_result = read_tool.execute(path: "src/app.rb")
    expect(read_result[:content]).to include("class App")
    
    # Modify the file
    new_content = read_result[:content].gsub("'world'", "'Hello, RubyLLM!'")
    write_result = write_tool.execute(path: "src/app.rb", content: new_content)
    expect(write_result[:bytes_written]).to be > 0
    
    # Verify the change
    verify_result = shell_tool.execute(command: "grep 'Hello, RubyLLM!' src/app.rb")
    expect(verify_result[:exit_code]).to eq(0)
    expect(verify_result[:stdout]).to include("Hello, RubyLLM!")
  end
  
  it "handles memory persistence across sessions" do
    memory1 = RubyLLM::Code::Memory.new
    memory1.add("project_name", "TestProject")
    memory1.add("preferred_style", "functional")
    
    # Simulate new session
    memory2 = RubyLLM::Code::Memory.new
    expect(memory2.get("project_name")).to eq("TestProject")
    expect(memory2.get("preferred_style")).to eq("functional")
    
    # Clean up
    memory2.clear
  end
  
  it "respects workspace boundaries" do
    read_tool = RubyLLM::Code::Tools::ReadFile.new(config)
    write_tool = RubyLLM::Code::Tools::WriteFile.new(config)
    
    # Should fail for paths outside workspace
    expect { read_tool.execute(path: "/etc/passwd") }.to raise_error(/workspace/)
    expect { write_tool.execute(path: "/tmp/test.txt", content: "test") }.to raise_error(/workspace/)
    
    # Should work for paths within workspace
    result = write_tool.execute(path: "allowed.txt", content: "safe content")
    expect(result[:error]).to be_nil
  end
  
  it "handles complex grep patterns with context" do
    # Create a Ruby file with methods
    ruby_content = <<~RUBY
      class Calculator
        def add(a, b)
          a + b
        end
        
        def subtract(a, b)
          a - b
        end
        
        def multiply(a, b)
          a * b
        end
      end
    RUBY
    
    create_test_file("calculator.rb", ruby_content)
    
    grep_tool = RubyLLM::Code::Tools::Grep.new(config)
    
    # Search for method definitions with context
    result = grep_tool.execute(
      pattern: "def \\w+\\(.*\\)",
      file_pattern: "*.rb",
      context_lines: 1
    )
    
    expect(result[:total_matches]).to eq(3)
    
    # Check context includes method body
    first_match = result[:matches].first[:matches].first
    expect(first_match[:context]).to include("a + b")
  end
end