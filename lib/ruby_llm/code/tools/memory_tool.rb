# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # rubocop:disable Style/Documentation
      class MemoryTool < BaseTool
        def name
          'Memory'
        end

        description 'Saves or retrieves information for future conversations'

        param :action, required: true,
                       desc: "Action to perform: 'save', 'get', 'list', or 'delete'"
        param :key, desc: 'Key for the memory item'
        param :value, desc: "Value to save (for 'save' action)"

        def execute(action:, key: nil, value: nil) # rubocop:disable Metrics/PerceivedComplexity
          memory = config.memory

          return { error: 'Memory is disabled in configuration' } unless memory

          case action
          when 'save'
            return { error: 'Key and value required for save' } unless key && value

            memory.add(key, value)
            { action: 'saved', key: key, value: value }

          when 'get'
            return { error: 'Key required for get' } unless key

            value = memory.get(key)
            if value
              { action: 'retrieved', key: key, value: value }
            else
              { error: "No memory found for key: #{key}" }
            end

          when 'list'
            facts = memory.all
            { action: 'list', count: facts.size, memories: facts }

          when 'delete'
            return { error: 'Key required for delete' } unless key

            memory.delete(key)
            { action: 'deleted', key: key }

          else
            { error: "Unknown action: #{action}. Use 'save', 'get', 'list', or 'delete'" }
          end
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
