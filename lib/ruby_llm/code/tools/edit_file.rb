# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # rubocop:disable Style/Documentation
      class EditFile < BaseTool
        def name
          'Edit'
        end

        def description
          <<~DESC
            Performs exact string replacements in files.#{' '}

            Usage:
            - You must use your `Read` tool at least once in the conversation before editing. This tool will error if you attempt an edit without reading the file.#{' '}
            - When editing text from Read tool output, ensure you preserve the exact indentation (tabs/spaces) as it appears AFTER the line number prefix. The line number prefix format is: spaces + line number + tab. Everything after that tab is the actual file content to match. Never include any part of the line number prefix in the old_string or new_string.
            - ALWAYS prefer editing existing files in the codebase. NEVER write new files unless explicitly required.
            - Only use emojis if the user explicitly requests it. Avoid adding emojis to files unless asked.
            - The edit will FAIL if `old_string` is not unique in the file. Either provide a larger string with more surrounding context to make it unique or use `replace_all` to change every instance of `old_string`.#{' '}
            - Use `replace_all` for replacing and renaming strings across the file. This parameter is useful if you want to rename a variable for instance.
          DESC
        end

        param :file_path, desc: 'The absolute path to the file to modify'
        param :old_string, desc: 'The text to replace'
        param :new_string, desc: 'The text to replace it with (must be different from old_string)'
        param :replace_all, desc: 'Replace all occurences of old_string (default false)', required: false

        def execute(file_path:, old_string:, new_string:, replace_all: false)
          abs_path = validate_path(file_path)

          return "Error: File not found: #{file_path}" unless File.exist?(abs_path)

          return 'Error: old_string and new_string cannot be the same' if old_string == new_string

          original = File.read(abs_path)

          return 'Error: old_string not found in file' unless original.include?(old_string)

          # Count occurrences
          occurrences = original.scan(old_string).length

          # Replace content
          if replace_all
            modified = original.gsub(old_string, new_string)
            occurrences
          else
            # Replace only first occurrence
            index = original.index(old_string)
            return 'Error: Could not find old_string in file' unless index

            modified = original[0...index] + new_string + original[(index + old_string.length)..]
            1

          end

          File.write(abs_path, modified)

          # Show snippet of the change
          snippet = show_change_snippet(modified, new_string)

          "The file #{file_path} has been updated. Here's the result of running `cat -n` on a snippet of the edited file:\n#{snippet}" # rubocop:disable Layout/LineLength
        rescue StandardError => e
          "Error: Failed to edit file: #{e.message}"
        end

        private

        def show_change_snippet(content, new_string)
          # Find the line containing the change
          lines = content.lines
          change_index = content.index(new_string)
          return '' unless change_index

          # Find which line contains the change
          char_count = 0
          line_num = 0
          lines.each_with_index do |line, idx|
            char_count += line.length
            if char_count >= change_index
              line_num = idx + 1
              break
            end
          end

          # Show 5 lines before and after
          start_line = [line_num - 5, 1].max
          end_line = [line_num + 5, lines.length].min

          snippet_lines = lines[(start_line - 1)...(end_line)]
          formatted_lines = snippet_lines.map.with_index do |line, idx|
            actual_line_num = start_line + idx
            format('%<line>6d→%<content>s', line: actual_line_num, content: line.chomp)
          end

          formatted_lines.join("\n")
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
