# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Code::Tools::Shell do
  let(:tool) { described_class.new(test_config) }
  
  describe "#execute" do
    it "executes simple commands" do
      result = tool.execute(command: "echo 'Hello, world!'")
      
      expect(result[:stdout]).to include("Hello, world!")
      expect(result[:exit_code]).to eq(0)
      expect(result[:error]).to be_nil
    end
    
    it "captures stderr" do
      result = tool.execute(command: "echo 'error' >&2")
      
      expect(result[:stderr]).to include("error")
      expect(result[:stdout]).to eq("(empty)")
    end
    
    it "respects working directory" do
      subdir = File.join(@temp_dir, "subdir")
      FileUtils.mkdir_p(subdir)
      
      result = tool.execute(command: "pwd", directory: "subdir")
      
      expect(result[:stdout]).to include("subdir")
    end
    
    it "handles command timeout" do
      result = tool.execute(command: "sleep 5", timeout: 1)
      
      expect(result[:stderr]).to include("timed out")
      expect(result[:exit_code]).to eq(-1)
    end
    
    it "reports command duration" do
      result = tool.execute(command: "echo test")
      
      expect(result[:duration]).to be_a(Numeric)
      expect(result[:duration]).to be > 0
    end
    
    it "truncates very long output" do
      result = tool.execute(command: "seq 1 20000")
      
      expect(result[:stdout]).to include("... (output truncated)")
      expect(result[:stdout].length).to be < 11_000
    end
    
    it "validates dangerous commands" do
      result = tool.execute(command: "rm -rf /")
      
      expect(result[:error]).to include("dangerous")
    end
    
    it "validates directory exists" do
      result = tool.execute(command: "pwd", directory: "nonexistent")
      
      expect(result[:error]).to include("Directory not found")
    end
  end
end