# frozen_string_literal: true

module RubyLLM::Code
  class MCPCommands
    def initialize(config)
      @config = config
      @mcp = config.mcp
    end
    
    def process(args)
      return self.class.show_help if args.empty?
      
      action = args.first
      case action
      when "list" then list_servers
      when "add" then add_server(args[1], args[2..])
      when "remove" then remove_server(args[1])
      when "tools" then list_tools(args[1])
      else
        self.class.show_help
      end
    end
    
    def self.show_help
      puts
      puts "● MCP commands:"
      puts Colors.dim("  /mcp list                                  - List MCP servers")
      puts Colors.dim("  /mcp add <name> <transport> <config...>    - Add MCP server")
      puts Colors.dim("  /mcp remove <name>                         - Remove MCP server")
      puts Colors.dim("  /mcp tools <name>                          - List tools from server")
      puts
    end
    
    private
    
    def list_servers
      servers = @mcp.list_servers
      if servers.empty?
        puts
        puts Colors.dim("● No MCP servers configured.")
        puts
      else
        puts
        puts "● MCP Servers:"
        servers.each do |name, info|
          if info[:connected]
            puts Colors.success("  #{name} (#{info[:transport_type]}):")
            puts Colors.dim("    Tools: #{info[:tools].join(', ')}") unless info[:tools].empty?
            puts Colors.dim("    Resources: #{info[:resources].join(', ')}") unless info[:resources].empty?
            puts Colors.dim("    Prompts: #{info[:prompts].join(', ')}") unless info[:prompts].empty?
          else
            puts Colors.error("  #{name} (disconnected): #{info[:error]}")
          end
        end
        puts
      end
    end
    
    def add_server(name, args)
      unless name && args.size >= 2
        puts
        puts Colors.error("● Usage: /mcp add <name> <transport> <config...>")
        puts Colors.dim("  Transport types: stdio, sse, streamable")
        puts Colors.dim("  Examples:")
        puts Colors.dim("    /mcp add myserver stdio node server.js")
        puts Colors.dim("    /mcp add myserver sse http://localhost:9292/mcp/sse")
        puts Colors.dim("    /mcp add myserver streamable http://localhost:8080/mcp")
        puts
        return
      end
      
      transport_type = args.first
      config_args = args[1..].join(" ")
      
      config = case transport_type
      when "stdio"
        parts = config_args.split(" ")
        {
          command: parts.first,
          args: parts[1..],
          env: {}
        }
      when "sse", "streamable"
        { url: config_args }
      else
        puts
        puts Colors.error("● Unknown transport type: #{transport_type}")
        puts
        return
      end
      
      begin
        @mcp.add_server(name, transport_type, config)
        puts
        puts Colors.success("● MCP server '#{name}' connected via #{transport_type}.")
        puts
      rescue => e
        puts
        puts Colors.error("● Failed to add MCP server: #{e.message}")
        puts
      end
    end
    
    def remove_server(name)
      unless name
        puts
        puts Colors.error("● Usage: /mcp remove <name>")
        puts
        return
      end
      
      @mcp.remove_server(name)
      puts
      puts Colors.success("● MCP server '#{name}' removed.")
      puts
    end
    
    def list_tools(name)
      unless name
        puts
        puts Colors.error("● Usage: /mcp tools <name>")
        puts
        return
      end
      
      client = @mcp.get_server(name)
      unless client
        puts
        puts Colors.error("● MCP server '#{name}' not found.")
        puts
        return
      end
      
      begin
        tools = client.tools
        if tools.empty?
          puts
          puts Colors.dim("● No tools available from server '#{name}'.")
          puts
        else
          puts
          puts "● Tools from '#{name}':"
          tools.each do |tool|
            puts Colors.dim("  #{tool.name}: #{tool.description}")
          end
          puts
        end
      rescue => e
        puts
        puts Colors.error("● Error getting tools: #{e.message}")
        puts
      end
    end
  end
end