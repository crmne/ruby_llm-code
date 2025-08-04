# frozen_string_literal: true

module RubyLLM::Code
  class Memory
    MEMORY_FILE = File.join(Configuration::CONFIG_DIR, "memory.yml")
    
    def initialize
      @facts = load_memory
    end
    
    def add(key, value)
      @facts[key] = {
        value: value,
        timestamp: Time.now,
        usage_count: 0
      }
      save_memory
    end
    
    def get(key)
      fact = @facts[key]
      return nil unless fact
      
      fact[:usage_count] += 1
      fact[:last_used] = Time.now
      save_memory
      
      fact[:value]
    end
    
    def all
      @facts.transform_values { |f| f[:value] }
    end
    
    def delete(key)
      @facts.delete(key)
      save_memory
    end
    
    def clear
      @facts = {}
      save_memory
    end
    
    def to_prompt
      return nil if @facts.empty?
      
      lines = ["# User Memory"]
      @facts.each do |key, fact|
        lines << "- #{key}: #{fact[:value]}"
      end
      
      lines.join("\n")
    end
    
    private
    
    def load_memory
      return {} unless File.exist?(MEMORY_FILE)
      
      # Use safe_load with permitted classes for security
      YAML.safe_load_file(MEMORY_FILE, permitted_classes: [Time, Symbol]) || {}
    rescue => e
      warn "Failed to load memory: #{e.message}"
      {}
    end
    
    def save_memory
      FileUtils.mkdir_p(File.dirname(MEMORY_FILE))
      File.write(MEMORY_FILE, @facts.to_yaml)
    rescue => e
      warn "Failed to save memory: #{e.message}"
    end
  end
end