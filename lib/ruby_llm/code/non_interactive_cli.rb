# frozen_string_literal: true

module RubyLLM::Code
  class NonInteractiveCLI
    def initialize(config, stream: true)
      @config = config
      @stream = stream
    end

    def run(input)
      return if input.strip.empty?

      chat = build_chat

      if @stream
        chat.ask(input) do |chunk|
          print chunk.content
          $stdout.flush
        end
        puts
      else
        response = chat.ask(input)
        puts response.content
      end
    rescue => e
      STDERR.puts "Error: #{e.message}"
      exit(1)
    end

    private

    def build_chat
      RubyLLMConfigurator.configure
      chat = RubyLLM.chat(model: @config.model)
      chat.with_instructions(Prompts.system_prompt(@config))

      if @config.tools_enabled
        chat.with_tools(
          Tools::ReadFile.new(@config),
          Tools::WriteFile.new(@config),
          Tools::EditFile.new(@config),
          Tools::ListDirectory.new(@config),
          Tools::Glob.new(@config),
          Tools::Grep.new(@config),
          Tools::Shell.new(@config),
          Tools::WebSearch.new(@config),
          Tools::WebFetch.new(@config),
          Tools::MemoryTool.new(@config)
        )
      end

      chat
    end

  end
end
