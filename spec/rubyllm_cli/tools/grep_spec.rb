# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLMCLI::Tools::Grep do
  let(:tool) { described_class.new(test_config) }
  
  describe "#execute" do
    it "searches for patterns in files" do
      create_test_file("file1.txt", "Hello world\nGoodbye world")
      create_test_file("file2.txt", "Hello Ruby\nHello Rails")
      
      result = tool.execute(pattern: "Hello")
      
      expect(result[:total_matches]).to eq(3)
      expect(result[:files_with_matches]).to eq(2)
      expect(result[:matches].map { |m| m[:file] }).to include("file1.txt", "file2.txt")
    end
    
    it "supports regex patterns" do
      create_test_file("test.rb", "def hello\nend\ndef world\nend")
      
      result = tool.execute(pattern: "def \\w+")
      
      expect(result[:total_matches]).to eq(2)
      matches = result[:matches].first[:matches]
      expect(matches[0][:content]).to eq("def hello")
      expect(matches[1][:content]).to eq("def world")
    end
    
    it "filters by file pattern" do
      create_test_file("test.rb", "ruby code")
      create_test_file("test.js", "javascript code")
      create_test_file("test.py", "python code")
      
      result = tool.execute(pattern: "code", file_pattern: "*.rb")
      
      expect(result[:files_with_matches]).to eq(1)
      expect(result[:matches].first[:file]).to eq("test.rb")
    end
    
    it "includes context lines" do
      content = (1..5).map { |i| "Line #{i}" }.join("\n")
      create_test_file("context.txt", content)
      
      result = tool.execute(pattern: "Line 3", context_lines: 1)
      
      match = result[:matches].first[:matches].first
      expect(match[:context]).to eq(["Line 2", "Line 3", "Line 4"])
    end
    
    it "handles invalid regex gracefully" do
      result = tool.execute(pattern: "[invalid")
      
      expect(result[:error]).to include("Invalid regex")
    end
    
    it "searches in specific file" do
      create_test_file("target.txt", "Find me")
      create_test_file("other.txt", "Find me too")
      
      result = tool.execute(pattern: "Find", path: "target.txt")
      
      expect(result[:files_with_matches]).to eq(1)
      expect(result[:matches].first[:file]).to eq("target.txt")
    end
    
    it "skips binary files" do
      create_test_file("binary.dat", "\x00\x01\x02Find\x03\x04")
      create_test_file("text.txt", "Find me")
      
      result = tool.execute(pattern: "Find")
      
      expect(result[:files_with_matches]).to eq(1)
      expect(result[:matches].first[:file]).to eq("text.txt")
    end
    
    it "respects gitignore patterns" do
      File.write(File.join(@temp_dir, ".gitignore"), "*.log\n")
      create_test_file("test.log", "Find me")
      create_test_file("test.txt", "Find me")
      
      result = tool.execute(pattern: "Find")
      
      expect(result[:files_with_matches]).to eq(1)
      expect(result[:matches].first[:file]).to eq("test.txt")
    end
  end
end