# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe RubyLLMCLI::CLI do
  let(:cli) { described_class.new }
  
  describe "#run" do
    it "runs in interactive mode when no arguments" do
      allow(STDIN).to receive(:tty?).and_return(true)
      expect(RubyLLMCLI::InteractiveCLI).to receive(:new).and_return(
        double(run: nil)
      )
      
      cli.run([])
    end
    
    it "runs in non-interactive mode with prompt argument" do
      expect(RubyLLMCLI::NonInteractiveCLI).to receive(:new).and_return(
        double(run: nil)
      )
      
      cli.run(["Hello, world!"])
    end
    
    it "runs in non-interactive mode when piped" do
      allow(STDIN).to receive(:tty?).and_return(false)
      allow(STDIN).to receive(:read).and_return("piped input")
      
      expect(RubyLLMCLI::NonInteractiveCLI).to receive(:new).and_return(
        double(run: nil)
      )
      
      cli.run([])
    end
    
    it "handles --help option" do
      expect { cli.run(["--help"]) }.to output(/Usage:/).to_stdout.and raise_error(SystemExit)
    end
    
    it "handles --version option" do
      expect { cli.run(["--version"]) }.to output(/RubyLLM CLI/).to_stdout.and raise_error(SystemExit)
    end
    
    it "sets model from command line" do
      expect(RubyLLMCLI::NonInteractiveCLI).to receive(:new) do |config, _|
        expect(config.model).to eq("gpt-4")
        double(run: nil)
      end
      
      cli.run(["--model", "gpt-4", "test"])
    end
    
    it "sets temperature from command line" do
      expect(RubyLLMCLI::NonInteractiveCLI).to receive(:new) do |config, _|
        expect(config.temperature).to eq(0.5)
        double(run: nil)
      end
      
      cli.run(["--temperature", "0.5", "test"])
    end
    
    it "loads config from file" do
      config_file = File.join(@temp_dir, "custom_config.yml")
      File.write(config_file, { "model" => "custom-model" }.to_yaml)
      
      expect(RubyLLMCLI::NonInteractiveCLI).to receive(:new) do |config, _|
        expect(config.model).to eq("custom-model")
        double(run: nil)
      end
      
      cli.run(["--config", config_file, "test"])
    end
    
    it "handles errors gracefully" do
      allow(RubyLLMCLI::InteractiveCLI).to receive(:new).and_raise("Test error")
      
      expect { cli.run([]) }.to output(/Error: Test error/).to_stderr.and raise_error(SystemExit)
    end
  end
end