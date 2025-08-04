# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Code::Memory do
  let(:memory) { described_class.new }
  let(:memory_file) { RubyLLM::Code::Memory::MEMORY_FILE }
  
  before do
    FileUtils.rm_f(memory_file)
  end
  
  after do
    FileUtils.rm_f(memory_file)
  end
  
  describe "#add" do
    it "stores a key-value pair" do
      memory.add("test_key", "test_value")
      expect(memory.get("test_key")).to eq("test_value")
    end
    
    it "persists to file" do
      memory.add("persistent", "value")
      new_memory = described_class.new
      expect(new_memory.get("persistent")).to eq("value")
    end
  end
  
  describe "#get" do
    it "returns nil for non-existent keys" do
      expect(memory.get("missing")).to be_nil
    end
    
    it "increments usage count" do
      memory.add("tracked", "value")
      memory.get("tracked")
      memory.get("tracked")
      
      data = YAML.load_file(memory_file)
      expect(data["tracked"][:usage_count]).to eq(2)
    end
  end
  
  describe "#all" do
    it "returns all stored values" do
      memory.add("key1", "value1")
      memory.add("key2", "value2")
      
      expect(memory.all).to eq({
        "key1" => "value1",
        "key2" => "value2"
      })
    end
  end
  
  describe "#delete" do
    it "removes a key" do
      memory.add("temp", "value")
      memory.delete("temp")
      expect(memory.get("temp")).to be_nil
    end
  end
  
  describe "#clear" do
    it "removes all keys" do
      memory.add("key1", "value1")
      memory.add("key2", "value2")
      memory.clear
      
      expect(memory.all).to be_empty
    end
  end
  
  describe "#to_prompt" do
    it "formats memories for prompt inclusion" do
      memory.add("user_preference", "dark mode")
      memory.add("project_path", "/home/user/project")
      
      prompt = memory.to_prompt
      expect(prompt).to include("# User Memory")
      expect(prompt).to include("user_preference: dark mode")
      expect(prompt).to include("project_path: /home/user/project")
    end
    
    it "returns nil when empty" do
      expect(memory.to_prompt).to be_nil
    end
  end
end