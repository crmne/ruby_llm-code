# frozen_string_literal: true

module RubyLLMCLI
  module Tools
    class WriteFile < BaseTool
      def name
        "Write"
      end
      
      def description
        <<~DESC
          Writes a file to the local filesystem.

          Usage:
          - This tool will overwrite the existing file if there is one at the provided path.
          - If this is an existing file, you MUST use the Read tool first to read the file's contents. This tool will fail if you did not read the file first.
          - ALWAYS prefer editing existing files in the codebase. NEVER write new files unless explicitly required.
          - NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
          - Only use emojis if the user explicitly requests it. Avoid writing emojis to files unless asked.
        DESC
      end
      
      param :file_path, desc: "The absolute path to the file to write (must be absolute, not relative)"
      param :content, desc: "The content to write to the file"
      
      def execute(file_path:, content:)
        abs_path = validate_path(file_path)
        
        # Check if file exists before writing
        was_created = !File.exist?(abs_path)
        
        # Ensure directory exists
        dir = File.dirname(abs_path)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        
        # Write file
        File.write(abs_path, content)
        
        "File #{was_created ? 'created' : 'written'} successfully at: #{file_path}"
      rescue => e
        "Error: Failed to write file: #{e.message}"
      end
    end
  end
end