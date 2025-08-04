# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # rubocop:disable Style/Documentation
      class WebSearch < BaseTool
        def name
          'WebSearch'
        end

        description 'Searches the web for information'

        param :query, desc: 'Search query'
        param :limit, type: 'integer', desc: 'Maximum number of results', required: false

        def execute(query:, limit: 5) # rubocop:disable Lint/UnusedMethodArgument
          # This is a placeholder implementation
          # In a real implementation, you would use a search API
          # like DuckDuckGo, Google Custom Search, or Bing

          {
            query: query,
            results: [
              {
                title: 'Example Result',
                url: 'https://example.com',
                snippet: 'This would be a real search result snippet...'
              }
            ],
            message: 'Web search requires API configuration'
          }
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
