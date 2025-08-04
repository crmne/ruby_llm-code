# frozen_string_literal: true

module RubyLLMCLI
  class OutputFormatter
    TOOL_DISPLAY_NAMES = {
      "LS" => "List",
      "TodoWrite" => "Todo"
    }.freeze
    
    def self.format_tool_call(tool_name, args)
      display_name = TOOL_DISPLAY_NAMES[tool_name] || tool_name
      "● #{Colors.tool(display_name)}#{Colors.dim("(#{format_args(args)})")}"
    end
    
    def self.format_tool_result(result, tool_name = nil)
      # Special handling for Read tool
      if tool_name == "Read" && args_include_file_path?(result)
        return format_read_tool_result(result)
      end
      
      # Special handling for TodoWrite tool
      if tool_name == "TodoWrite" || (result.is_a?(String) && result.include?("Todos have been modified"))
        return format_todo_tool_result(result)
      end
      
      lines = []
      
      if result.is_a?(Hash)
        if result[:error]
          lines << Colors.error("  ⎿  Error: #{result[:error]}")
        elsif result[:content]
          format_content(result[:content], lines)
        elsif result.empty?
          lines << Colors.dim("  ⎿  (No content)")
        else
          # Format hash results
          result.each do |key, value|
            if value.is_a?(Array) && !value.empty?
              lines << Colors.dim("  ⎿  #{key}: #{value.length} items")
            elsif value.is_a?(String) && value.length > 100
              lines << Colors.dim("  ⎿  #{key}: #{value[0..97]}...")
            else
              lines << Colors.dim("  ⎿  #{key}: #{value}")
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
    
    def self.format_read_tool_result(result)
      # For Read tool, just show the file path without content
      lines = []
      lines << Colors.dim("  ⎿  File read successfully")
      lines.join("\n")
    end
    
    def self.format_todo_tool_result(result)
      lines = []
      
      # Try to load current todos
      todos = RubyLLMCLI::Tools::TodoWrite.load_current_todos
      
      if todos && !todos.empty?
        lines << "● Update Todos"
        
        todos.each_with_index do |todo, index|
          # Use ☒ for completed tasks, ☐ for others
          checkbox = todo["status"] == "completed" ? "☒" : "☐"
          
          # Handle both "content" and "task" fields for backwards compatibility
          content = todo["content"] || todo["task"] || "No description"
          
          # Apply strikethrough for completed tasks
          if todo["status"] == "completed"
            formatted_content = Colors.strikethrough(content)
          else
            formatted_content = content
          end
          
          # First item uses ⎿, rest use spaces for indentation
          if index == 0
            lines << Colors.dim("  ⎿  #{checkbox} #{formatted_content}")
          else
            lines << Colors.dim("     #{checkbox} #{formatted_content}")
          end
        end
      else
        lines << Colors.dim("  ⎿  Todo list updated")
      end
      
      lines.join("\n")
    end
    
    def self.args_include_file_path?(result)
      result.is_a?(String) && result.match?(/^\s*\d+→/)
    end
    
    def self.format_todo_result(todos)
      lines = [Colors.dim("  ⎿  Update Todos")]
      todos.each do |todo|
        status_icon = todo["status"] == "completed" ? "☒" : "☐"
        lines << Colors.dim("     #{status_icon} #{todo["content"]}")
      end
      lines.join("\n")
    end
    
    private
    
    def self.format_content(content, lines)
      content_lines = content.to_s.split("\n")
      
      if content_lines.length == 1 && content_lines.first.length <= 100
        lines << Colors.dim("  ⎿  #{content_lines.first}")
      elsif content_lines.empty? || content.to_s.strip.empty?
        lines << Colors.dim("  ⎿  (No content)")
      else
        # Show first few lines
        preview_lines = content_lines.take(5)
        preview_lines.each_with_index do |line, i|
          if i == 0
            lines << Colors.dim("  ⎿  #{line}")
          else
            lines << Colors.dim("     #{line}")
          end
        end
        
        if content_lines.length > 5
          lines << Colors.dim("     … +#{content_lines.length - 5} lines")
        end
      end
    end
    
    def self.format_args(args)
      return "" if args.nil? || args.empty?
      
      case args
      when String
        args
      when Hash
        if args.empty?
          ""
        else
          formatted = args.map do |k, v|
            value_str = case v
                       when String
                         # Don't truncate file paths
                         if k.to_s == "file_path"
                           v
                         else
                           v.length > 50 ? "#{v[0..47]}..." : v
                         end
                       when Array
                         "[#{v.length} items]"
                       when Hash
                         "{#{v.length} keys}"
                       else
                         v.to_s
                       end
            "#{k}: #{value_str}"
          end.join(", ")
          formatted
        end
      else
        args.to_s
      end
    end
  end
end