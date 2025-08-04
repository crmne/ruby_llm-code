# frozen_string_literal: true

module RubyLLM
  module Code
    # rubocop:disable Style/Documentation
    class OutputFormatter
      TOOL_DISPLAY_NAMES = {
        'LS' => 'List',
        'TodoWrite' => 'Todo'
      }.freeze

      def self.format_tool_call(tool_name, args)
        display_name = TOOL_DISPLAY_NAMES[tool_name] || tool_name
        "● #{Colors.tool(display_name)}#{Colors.dim("(#{format_args(args)})")}"
      end

      def self.format_tool_result(result, tool_name = nil) # rubocop:disable Metrics/PerceivedComplexity
        # Special handling for Read tool
        return format_read_tool_result(result) if tool_name == 'Read' && args_include_file_path?(result)

        # Special handling for TodoWrite tool
        if tool_name == 'TodoWrite' || (result.is_a?(String) && result.include?('Todos have been modified'))
          return format_todo_tool_result(result)
        end

        lines = []

        if result.is_a?(Hash)
          if result[:error]
            lines << Colors.error("  ⎿  Error: #{result[:error]}")
          elsif result[:content]
            format_content(result[:content], lines)
          elsif result.empty?
            lines << Colors.dim('  ⎿  (No content)')
          else
            # Format hash results
            result.each do |key, value|
              lines << if value.is_a?(Array) && !value.empty?
                         Colors.dim("  ⎿  #{key}: #{value.length} items")
                       elsif value.is_a?(String) && value.length > 100
                         Colors.dim("  ⎿  #{key}: #{value[0..97]}...")
                       else
                         Colors.dim("  ⎿  #{key}: #{value}")
                       end
            end
          end
        elsif result.is_a?(String)
          format_content(result, lines)
        else
          lines << Colors.dim("  ⎿  #{result.inspect}")
        end

        lines.join("\n")
      end

      def self.format_read_tool_result(_result)
        # For Read tool, just show the file path without content
        lines = []
        lines << Colors.dim('  ⎿  File read successfully')
        lines.join("\n")
      end

      def self.format_todo_tool_result(_result) # rubocop:disable Metrics/PerceivedComplexity
        lines = []

        # Try to load current todos
        todos = RubyLLM::Code::Tools::TodoWrite.load_current_todos

        if todos && !todos.empty?
          lines << '● Update Todos'

          todos.each_with_index do |todo, index|
            # Use ☒ for completed tasks, ☐ for others
            checkbox = todo['status'] == 'completed' ? '☒' : '☐'

            # Handle both "content" and "task" fields for backwards compatibility
            content = todo['content'] || todo['task'] || 'No description'

            # Apply strikethrough for completed tasks
            formatted_content = if todo['status'] == 'completed'
                                  Colors.strikethrough(content)
                                else
                                  content
                                end

            # First item uses ⎿, rest use spaces for indentation
            lines << if index.zero?
                       Colors.dim("  ⎿  #{checkbox} #{formatted_content}")
                     else
                       Colors.dim("     #{checkbox} #{formatted_content}")
                     end
          end
        else
          lines << Colors.dim('  ⎿  Todo list updated')
        end

        lines.join("\n")
      end

      def self.args_include_file_path?(result)
        result.is_a?(String) && result.match?(/^\s*\d+→/)
      end

      def self.format_todo_result(todos)
        lines = [Colors.dim('  ⎿  Update Todos')]
        todos.each do |todo|
          status_icon = todo['status'] == 'completed' ? '☒' : '☐'
          lines << Colors.dim("     #{status_icon} #{todo['content']}")
        end
        lines.join("\n")
      end

      def self.format_content(content, lines) # rubocop:disable Metrics/PerceivedComplexity
        content_lines = content.to_s.split("\n")

        if content_lines.length == 1 && content_lines.first.length <= 100
          lines << Colors.dim("  ⎿  #{content_lines.first}")
        elsif content_lines.empty? || content.to_s.strip.empty?
          lines << Colors.dim('  ⎿  (No content)')
        else
          # Show first few lines
          preview_lines = content_lines.take(5)
          preview_lines.each_with_index do |line, i|
            lines << if i.zero?
                       Colors.dim("  ⎿  #{line}")
                     else
                       Colors.dim("     #{line}")
                     end
          end

          lines << Colors.dim("     … +#{content_lines.length - 5} lines") if content_lines.length > 5
        end
      end

      def self.format_args(args) # rubocop:disable Metrics/PerceivedComplexity
        return '' if args.nil? || args.empty?

        case args
        when String
          args
        when Hash
          if args.empty?
            ''
          else
            args.map do |k, v|
              value_str = case v
                          when String
                            # Don't truncate file paths
                            # rubocop:disable Metrics/BlockNesting
                            if k.to_s == 'file_path'
                              v
                            else
                              v.length > 50 ? "#{v[0..47]}..." : v
                            end
                            # rubocop:enable Metrics/BlockNesting
                          when Array
                            "[#{v.length} items]"
                          when Hash
                            "{#{v.length} keys}"
                          else
                            v.to_s
                          end
              "#{k}: #{value_str}"
            end.join(', ')

          end
        else
          args.to_s
        end
      end
    end
    # rubocop:enable Style/Documentation
  end
end
