# frozen_string_literal: true

module RubyLLMCLI
  class CommandProcessor
    COMMANDS = {
      help: "Show this help",
      quit: "Exit the application", 
      exit: "Exit the application",
      clear: "Clear conversation history",
      model: "Change or show current model",
      models: "List available models",
      save: "Save conversation",
      load: "Load conversation",
      memory: "Manage saved memories",
      tools: "Toggle tools on/off",
      mcp: "Manage MCP servers"
    }.freeze
    
    def initialize(config, conversation_manager)
      @config = config
      @conversation = conversation_manager
    end
    
    def process(input)
      return false unless input.start_with?("/")
      
      parts = input.split
      command = parts.first[1..].to_sym
      args = parts[1..]
      
      case command
      when :help then show_help
      when :quit, :exit then :exit
      when :clear then clear_conversation
      when :model then change_model(args.join(" "))
      when :models then list_models
      when :save then save_conversation(args.first)
      when :load then load_conversation(args.first)
      when :memory then MemoryCommands.new(@config).process(args)
      when :tools then toggle_tools
      when :mcp then MCPCommands.new(@config).process(args)
      else
        puts
        puts Colors.error("● Unknown command. Type /help for available commands.")
        puts
      end
      
      true
    end
    
    private
    
    def show_help
      puts
      puts "● Available commands:"
      COMMANDS.each do |cmd, desc|
        puts Colors.dim("  /#{cmd.to_s.ljust(12)} - #{desc}")
      end
      puts
      
      MemoryCommands.show_help
      MCPCommands.show_help
    end
    
    def clear_conversation
      @conversation.clear
      puts
      puts Colors.success("● Conversation cleared.")
      puts
    end
    
    def change_model(model_name)
      if model_name.empty?
        puts
        puts "● Current model: #{Colors.model(@config.model)}"
        puts
      else
        @config.model = model_name
        @conversation.clear
        @config.save
        puts
        puts Colors.success("● Model changed to: #{Colors.model(model_name)}")
        puts
      end
    end
    
    def list_models
      puts
      puts "● Available models:"
      RubyLLM::Models.all.group_by(&:provider).each do |provider, models|
        puts
        puts Colors.colorize("  #{provider}:", Colors::BOLD)
        models.each { |m| puts Colors.dim("    #{m.id}") }
      end
      puts
    end
    
    def save_conversation(filename)
      filename ||= "conversation_#{Time.now.strftime('%Y%m%d_%H%M%S')}.yml"
      @conversation.save(filename)
      puts
      puts Colors.success("● Conversation saved to: #{filename}")
      puts
    end
    
    def load_conversation(filename)
      unless filename
        puts
        puts Colors.error("● Usage: /load <filename>")
        puts
        return
      end
      
      if @conversation.load(filename)
        puts
        puts Colors.success("● Loaded conversation from: #{filename}")
        puts
      else
        puts
        puts Colors.error("● File not found: #{filename}")
        puts
      end
    end
    
    def toggle_tools
      @config.tools_enabled = !@config.tools_enabled
      @conversation.clear
      @config.save
      status = @config.tools_enabled ? "enabled" : "disabled"
      puts
      puts Colors.success("● Tools #{status}.")
      puts
    end
  end
end