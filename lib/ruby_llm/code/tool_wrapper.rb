# frozen_string_literal: true

module RubyLLM
  module Code
    # rubocop:disable Style/Documentation
    class ToolWrapper
      attr_reader :tool, :on_result

      def initialize(tool, on_result: nil)
        @tool = tool
        @on_result = on_result
        @last_call = nil
      end

      def name
        @tool.name
      end

      def id
        @tool.id
      end

      def description
        @tool.description
      end

      def parameters
        @tool.parameters
      end

      def call(arguments)
        @last_call = { name: name, arguments: arguments }
        result = @tool.call(arguments)

        # Notify callback with tool info and result
        @on_result&.call(@last_call, result)

        result
      end

      def to_h
        @tool.to_h
      end
    end
    # rubocop:enable Style/Documentation
  end
end
