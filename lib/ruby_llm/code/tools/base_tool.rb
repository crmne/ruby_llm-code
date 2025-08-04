# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # rubocop:disable Style/Documentation
      class BaseTool < RubyLLM::Tool
        attr_reader :config, :workspace

        def initialize(config)
          @config = config
          @workspace = config.workspace
          super()
        end

        # RubyLLM already provides param method, no need to override

        protected

        def validate_path(path)
          workspace.absolute_path(path).tap do |abs_path|
            raise 'Path outside workspace' unless workspace.within?(abs_path)
          end
        end

        def format_output(content, truncated: false)
          if truncated
            "#{content}\n... (output truncated)"
          else
            content
          end
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
