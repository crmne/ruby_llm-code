# frozen_string_literal: true

module RubyLLM::Code
  class MemoryCommands
    def initialize(config)
      @config = config
      @memory = config.memory
    end
    
    def process(args)
      return self.class.show_help if args.empty?
      
      action = args.first
      case action
      when "list" then list_memories
      when "save" then save_memory(args[1], args[2..].join(" "))
      when "get" then get_memory(args[1])
      when "delete" then delete_memory(args[1])
      else
        self.class.show_help
      end
    end
    
    def self.show_help
      puts
      puts "● Memory commands:"
      puts Colors.dim("  /memory list              - List all memories")
      puts Colors.dim("  /memory save <key> <val>  - Save a memory")
      puts Colors.dim("  /memory get <key>         - Get a memory")
      puts Colors.dim("  /memory delete <key>      - Delete a memory")
      puts
    end
    
    private
    
    def list_memories
      memories = @memory.all
      if memories.empty?
        puts
        puts Colors.dim("● No memories saved.")
        puts
      else
        puts
        puts "● Saved memories:"
        memories.each { |k, v| puts Colors.dim("  #{k}: #{v}") }
        puts
      end
    end
    
    def save_memory(key, value)
      unless key && value
        puts
        puts Colors.error("● Usage: /memory save <key> <value>")
        puts
        return
      end
      
      @memory.add(key, value)
      puts
      puts Colors.success("● Memory saved: #{key} = #{value}")
      puts
    end
    
    def get_memory(key)
      unless key
        puts
        puts Colors.error("● Usage: /memory get <key>")
        puts
        return
      end
      
      value = @memory.get(key)
      if value
        puts
        puts "● #{key}: #{value}"
        puts
      else
        puts
        puts Colors.error("● No memory found for: #{key}")
        puts
      end
    end
    
    def delete_memory(key)
      unless key
        puts
        puts Colors.error("● Usage: /memory delete <key>")
        puts
        return
      end
      
      @memory.delete(key)
      puts
      puts Colors.success("● Memory deleted: #{key}")
      puts
    end
  end
end