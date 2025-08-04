# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLMCLI::Tools::WriteFile do
  let(:tool) { described_class.new(test_config) }
  
  describe "#execute" do
    it "writes content to a new file" do
      result = tool.execute(path: "new_file.txt", content: "Hello, world!")
      
      expect(result[:bytes_written]).to eq(13)
      expect(result[:created]).to be true
      expect(File.read(File.join(@temp_dir, "new_file.txt"))).to eq("Hello, world!")
    end
    
    it "overwrites existing files" do
      existing = create_test_file("existing.txt", "old content")
      
      result = tool.execute(path: existing, content: "new content")
      
      expect(result[:created]).to be false
      expect(File.read(existing)).to eq("new content")
    end
    
    it "creates parent directories" do
      result = tool.execute(path: "deep/nested/file.txt", content: "test")
      
      expect(result[:error]).to be_nil
      expect(File.exist?(File.join(@temp_dir, "deep/nested/file.txt"))).to be true
    end
    
    it "validates workspace boundaries" do
      expect {
        tool.execute(path: "/tmp/outside.txt", content: "test")
      }.to raise_error(/must be within workspace/)
    end
    
    it "handles write errors gracefully" do
      allow(File).to receive(:write).and_raise(Errno::EACCES)
      
      result = tool.execute(path: "file.txt", content: "test")
      
      expect(result[:error]).to include("Failed to write file")
    end
  end
end