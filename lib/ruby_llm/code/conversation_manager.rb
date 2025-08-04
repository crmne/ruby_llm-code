# frozen_string_literal: true

module RubyLLM::Code
  class ConversationManager
    attr_reader :messages, :chat
    
    def initialize(config)
      @config = config
      @messages = []
      @chat = nil
    end
    
    def add_message(role:, content:)
      @messages << { role: role, content: content }
    end
    
    def clear
      @chat = nil
      @messages.clear
    end
    
    def save(filename)
      path = conversation_path(filename)
      FileUtils.mkdir_p(File.dirname(path))
      
      data = {
        "model" => chat.model.id,
        "messages" => messages_for_save,
        "timestamp" => Time.now
      }
      
      File.write(path, data.to_yaml)
    end
    
    def load(filename)
      path = conversation_path(filename)
      return false unless File.exist?(path)
      
      data = YAML.load_file(path)
      @config.model = data["model"]
      clear
      
      data["messages"].each do |msg|
        chat.add_message(role: msg["role"].to_sym, content: msg["content"])
      end
      
      true
    end
    
    def chat
      @chat ||= build_chat
    end
    
    private
    
    def build_chat
      RubyLLMConfigurator.configure
      RubyLLM.chat(model: @config.model)
        .with_instructions(Prompts.system_prompt(@config))
        .tap { |c| configure_tools(c) if @config.tools_enabled }
    end
    
    def configure_tools(chat)
      wrapped_tools = available_tools.map do |tool|
        ToolWrapper.new(tool, on_result: method(:handle_tool_result))
      end
      
      wrapped_tools.concat(@config.mcp.available_tools) if @config.mcp
      chat.with_tools(*wrapped_tools)
    end
    
    def available_tools
      Tools.constants
        .map { |const| Tools.const_get(const) }
        .select { |klass| klass < Tools::BaseTool }
        .map { |klass| klass.new(@config) }
    end
    
    def handle_tool_result(tool_call, result)
      puts
      puts OutputFormatter.format_tool_call(tool_call[:name], tool_call[:arguments])
      puts OutputFormatter.format_tool_result(result, tool_call[:name])
      $stdout.flush
    end
    
    def conversation_path(filename)
      File.join(Config::CONFIG_DIR, "conversations", filename)
    end
    
    def messages_for_save
      chat.messages.map do |msg|
        { "role" => msg.role.to_s, "content" => msg.content.to_s }
      end
    end
    
  end
end