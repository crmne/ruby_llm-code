# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLMCLI::Workspace do
  let(:workspace) { described_class.new(@temp_dir) }
  
  describe "#within?" do
    it "returns true for paths within workspace" do
      expect(workspace.within?(File.join(@temp_dir, "subdir", "file.rb"))).to be true
    end
    
    it "returns false for paths outside workspace" do
      expect(workspace.within?("/tmp/outside/file.rb")).to be false
    end
  end
  
  describe "#relative_path" do
    it "converts absolute paths to relative" do
      abs_path = File.join(@temp_dir, "src", "file.rb")
      expect(workspace.relative_path(abs_path)).to eq("src/file.rb")
    end
    
    it "handles paths outside workspace" do
      expect(workspace.relative_path("/tmp/file.rb")).to eq("/tmp/file.rb")
    end
  end
  
  describe "#absolute_path" do
    it "converts relative paths to absolute" do
      expect(workspace.absolute_path("src/file.rb")).to eq(File.join(@temp_dir, "src/file.rb"))
    end
    
    it "returns absolute paths unchanged" do
      abs_path = "/tmp/file.rb"
      expect(workspace.absolute_path(abs_path)).to eq(abs_path)
    end
  end
  
  describe "#git?" do
    it "returns true when .git directory exists" do
      FileUtils.mkdir_p(File.join(@temp_dir, ".git"))
      expect(workspace.git?).to be true
    end
    
    it "returns false when .git directory doesn't exist" do
      expect(workspace.git?).to be false
    end
  end
end

RSpec.describe RubyLLMCLI::GitIgnore do
  let(:gitignore) { described_class.new(@temp_dir) }
  
  describe "#ignored?" do
    before do
      File.write(File.join(@temp_dir, ".gitignore"), "*.log\nnode_modules/\n")
    end
    
    it "ignores files matching patterns" do
      expect(gitignore.ignored?("test.log")).to be true
      expect(gitignore.ignored?("node_modules/package.json")).to be true
    end
    
    it "doesn't ignore non-matching files" do
      expect(gitignore.ignored?("test.rb")).to be false
      expect(gitignore.ignored?("src/app.js")).to be false
    end
  end
end