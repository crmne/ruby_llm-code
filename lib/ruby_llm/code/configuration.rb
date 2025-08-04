# frozen_string_literal: true

module RubyLLM::Code
  class Configuration
    CONFIG_DIR = File.expand_path("~/.rubyllm")
    CONFIG_FILE = File.join(CONFIG_DIR, "config.yml")
    
    # Define configurable attributes
    ATTRIBUTES = %i[
      model temperature system_prompt tools_enabled
      auto_approval memory_enabled workspace_dir
    ].freeze
    
    # Create attr_accessors for all attributes
    attr_accessor(*ATTRIBUTES)
    
    # Simple delegations
    def workspace
      workspace_manager
    end
    
    def memory
      memory_manager
    end
    
    def mcp
      mcp_manager
    end
    
    def initialize
      set_defaults
      ensure_config_dir
      load_config
    end
    
    def save
      File.write(CONFIG_FILE, to_hash.to_yaml)
    end
    
    def load_file(path)
      return unless File.exist?(path)
      
      from_hash(YAML.load_file(path))
    rescue => e
      warn "Failed to load config: #{e.message}"
    end
    
    def to_hash
      ATTRIBUTES.each_with_object({}) do |attr, hash|
        value = send(attr)
        hash[attr.to_s] = value unless value.nil?
      end
    end
    
    def from_hash(data)
      data.each do |key, value|
        setter = "#{key}="
        send(setter, value) if respond_to?(setter)
      end
    end
    
    private
    
    def set_defaults
      @model = ENV["RUBYLLM_MODEL"] || "claude-3-5-haiku-20241022"
      @temperature = 0.7
      @system_prompt = nil
      @tools_enabled = true
      @auto_approval = []
      @memory_enabled = true
      @workspace_dir = Dir.pwd
    end
    
    def ensure_config_dir
      FileUtils.mkdir_p(CONFIG_DIR)
    end
    
    def load_config
      load_file(CONFIG_FILE)
    end
    
    def workspace_manager
      @workspace_manager ||= Workspace.new(workspace_dir)
    end
    
    def memory_manager
      @memory_manager ||= Memory.new if memory_enabled
    end
    
    def mcp_manager
      @mcp_manager ||= MCPManager.new(self)
    end
    
  end
end