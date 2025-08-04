# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # rubocop:disable Style/Documentation
      class MultiEdit < BaseTool
        def name
          'MultiEdit'
        end

        description <<~DESC
          This is a tool for making multiple edits to a single file in one operation. It is built on top of the Edit tool and allows you to perform multiple find-and-replace operations efficiently. Prefer this tool over the Edit tool when you need to make multiple edits to the same file.

          Before using this tool:

          1. Use the Read tool to understand the file's contents and context
          2. Verify the directory path is correct

          To make multiple file edits, provide the following:
          1. file_path: The absolute path to the file to modify (must be absolute, not relative)
          2. edits: An array of edit operations to perform, where each edit contains:
             - old_string: The text to replace (must match the file contents exactly, including all whitespace and indentation)
             - new_string: The edited text to replace the old_string
             - replace_all: Replace all occurences of old_string. This parameter is optional and defaults to false.

          IMPORTANT:
          - All edits are applied in sequence, in the order they are provided
          - Each edit operates on the result of the previous edit # rubocop:disable Layout/LineLength
          - All edits must be valid for the operation to succeed - if any edit fails, none will be applied
          - This tool is ideal when you need to make several changes to different parts of the same file
          - For Jupyter notebooks (.ipynb files), use the NotebookEdit instead

          CRITICAL REQUIREMENTS:
          1. All edits follow the same requirements as the single Edit tool
          2. The edits are atomic - either all succeed or none are applied
          3. Plan your edits carefully to avoid conflicts between sequential operations

          WARNING:
          - The tool will fail if edits.old_string doesn't match the file contents exactly (including whitespace)
          - The tool will fail if edits.old_string and edits.new_string are the same
          - Since edits are applied in sequence, ensure that earlier edits don't affect the text that later edits are trying to find

          When making edits:
          - Ensure all edits result in idiomatic, correct code
          - Do not leave the code in a broken state
          - Always use absolute file paths (starting with /)
          - Only use emojis if the user explicitly requests it. Avoid adding emojis to files unless asked.
          - Use replace_all for replacing and renaming strings across the file. This parameter is useful if you want to rename a variable for instance.

          If you want to create a new file, use:
          - A new file path, including dir name if needed
          - First edit: empty old_string and the new file's contents as new_string
          - Subsequent edits: normal edit operations on the created content
        DESC

        param :file_path, desc: 'The absolute path to the file to modify'
        param :edits, type: 'array', desc: 'Array of edit operations to perform sequentially on the file'

        def execute(file_path:, edits:) # rubocop:disable Metrics/PerceivedComplexity
          abs_path = validate_path(file_path)

          # Check if file exists
          raise "File does not exist: #{abs_path}" if !File.exist?(abs_path) && !edits.first['old_string'].empty?

          # Read current content or start with empty for new files
          content = File.exist?(abs_path) ? File.read(abs_path) : ''
          content.dup

          # Apply edits sequentially
          edits.each_with_index do |edit, index|
            old_string = edit['old_string']
            new_string = edit['new_string']
            replace_all = edit['replace_all'] || false

            # Validate edit
            raise "Edit #{index + 1}: old_string and new_string cannot be the same" if old_string == new_string

            # For new file creation, allow empty old_string
            if old_string.empty? && index.zero? && !File.exist?(abs_path)
              content = new_string
              next
            end

            # Check if old_string exists in content
            raise "Edit #{index + 1}: old_string not found in file" unless content.include?(old_string)

            # Apply the edit
            if replace_all
              content = content.gsub(old_string, new_string)
            else
              # Replace only first occurrence
              index = content.index(old_string)
              content = content[0...index] + new_string + content[(index + old_string.length)..] if index
            end
          end

          # Write the final content
          FileUtils.mkdir_p(File.dirname(abs_path))
          File.write(abs_path, content)

          # Return summary
          edit_count = edits.length
          "Successfully applied #{edit_count} edit#{'s' if edit_count > 1} to #{file_path}"
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
