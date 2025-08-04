# frozen_string_literal: true

module RubyLLM
  module Code
    # rubocop:disable Style/Documentation
    class MCPManager
      def initialize(config)
        @config = config
        @clients = {}
        load_mcp_config
      end

      def available_tools
        tools = []

        @clients.each do |name, client_info|
          client_info[:client].tools.each do |tool|
            tools << tool
          end
        rescue StandardError => e
          warn "Failed to get tools from #{name}: #{e.message}"
        end

        tools
      end

      def add_server(name, transport_type, config)
        client = RubyLLM::MCP.client(
          name: name,
          transport_type: transport_type.to_sym,
          config: config
        )

        @clients[name] = {
          client: client,
          transport_type: transport_type,
          config: config
        }
        save_mcp_config

        client
      rescue StandardError => e
        raise "Failed to connect to MCP server: #{e.message}"
      end

      def remove_server(name)
        client = @clients[name]
        return unless client

        @clients.delete(name)
        save_mcp_config
      end

      def list_servers
        @clients.transform_values do |client_info|
          client = client_info[:client]
          {
            connected: true,
            transport_type: client_info[:transport_type],
            tools: client.tools.map(&:name),
            resources: client.resources.map(&:name),
            prompts: client.prompts.map(&:name)
          }
        rescue StandardError => e
          {
            connected: false,
            error: e.message
          }
        end
      end

      def get_server(name)
        client_info = @clients[name]
        client_info ? client_info[:client] : nil
      end

      private

      def load_mcp_config
        config_file = File.join(Configuration::CONFIG_DIR, 'mcp_servers.yml')
        return unless File.exist?(config_file)

        config = YAML.load_file(config_file)
        config.each do |name, settings|
          add_server(name, settings['transport_type'], settings['config'])
        rescue StandardError => e
          warn "Failed to connect to MCP server '#{name}': #{e.message}"
        end
      rescue StandardError => e
        warn "Failed to load MCP config: #{e.message}"
      end

      def save_mcp_config
        config_file = File.join(Configuration::CONFIG_DIR, 'mcp_servers.yml')

        config = {}
        @clients.each do |name, client_info|
          config[name] = {
            'transport_type' => client_info[:transport_type].to_s,
            'config' => client_info[:config]
          }
        end

        FileUtils.mkdir_p(File.dirname(config_file))
        File.write(config_file, config.to_yaml)
      end
    end
    # rubocop:enable Style/Documentation
  end
end
