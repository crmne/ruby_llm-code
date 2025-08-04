# frozen_string_literal: true

module RubyLLM::Code
  module Tools
    class ReadFile < BaseTool
      def name
        "Read"
      end
      description <<~DESC
          Reads a file from the local filesystem. You can access any file directly by using this tool.
          Assume this tool is able to read all files on the machine. If the User provides a path to a file assume that path is valid. It is okay to read a file that does not exist; an error will be returned.

          Usage:
          - The file_path parameter must be an absolute path, not a relative path
          - By default, it reads up to 2000 lines starting from the beginning of the file
          - You can optionally specify a line offset and limit (especially handy for long files), but it's recommended to read the whole file by not providing these parameters
          - Any lines longer than 2000 characters will be truncated
          - Results are returned using cat -n format, with line numbers starting at 1
          - This tool allows Claude Code to read images (eg PNG, JPG, etc). When reading an image file the contents are presented visually as Claude Code is a multimodal LLM.
          - This tool can read PDF files (.pdf). PDFs are processed page by page, extracting both text and visual content for analysis.
          - For Jupyter notebooks (.ipynb files), use the NotebookRead instead
          - You have the capability to call multiple tools in a single response. It is always better to speculatively read multiple files as a batch that are potentially useful.
          - You will regularly be asked to read screenshots. If the user provides a path to a screenshot ALWAYS use this tool to view the file at the path. This tool will work with all temporary file paths like /var/folders/123/abc/T/TemporaryItems/NSIRD_screencaptureui_ZfB1tD/Screenshot.png
          - If you read a file that exists but has empty contents you will receive a system reminder warning in place of file contents.
        DESC
      
      param :file_path, desc: "The absolute path to the file to read"
      param :offset, type: "integer", desc: "The line number to start reading from. Only provide if the file is too large to read at once", required: false
      param :limit, type: "integer", desc: "The number of lines to read. Only provide if the file is too large to read at once.", required: false
      
      def execute(file_path:, offset: nil, limit: nil)
        abs_path = validate_path(file_path)
        
        unless File.exist?(abs_path)
          return "Error: File not found: #{file_path}"
        end
        
        if File.directory?(abs_path)
          return "Error: Path is a directory, not a file: #{file_path}"
        end
        
        content = read_file_content(abs_path, offset, limit)
        
        # Format with line numbers like cat -n
        lines = content.lines
        start_line = offset || 1
        
        formatted_lines = lines.map.with_index do |line, idx|
          line_num = start_line + idx
          # Format: spaces + line number + arrow + content
          "%6d→%s" % [line_num, line.chomp]
        end
        
        formatted_content = formatted_lines.join("\n")
        
        # Add system reminder for empty files
        if content.strip.empty? && File.exist?(abs_path)
          formatted_content + "\n\n<system-reminder>This file exists but has empty contents.</system-reminder>"
        else
          formatted_content
        end
      end
      
      private
      
      def read_file_content(path, offset, limit)
        if binary_file?(path)
          return "[Binary file - #{File.size(path)} bytes]"
        end
        
        lines = File.readlines(path)
        
        # Default to 2000 lines max
        limit ||= 2000
        
        if offset || limit
          start_line = (offset || 1) - 1
          end_line = limit ? start_line + limit - 1 : -1
          lines = lines[start_line..end_line] || []
        end
        
        # Truncate long lines
        lines = lines.map do |line|
          if line.length > 2000
            line[0...2000] + "... (line truncated)"
          else
            line
          end
        end
        
        content = lines.join
        
        # Truncate very large outputs
        if content.length > 50_000
          format_output(content[0...50_000], truncated: true)
        else
          content
        end
      end
      
      def binary_file?(path)
        # Simple heuristic: check if file contains null bytes
        File.open(path, "rb") do |f|
          sample = f.read(8192) || ""
          return sample.include?("\x00")
        end
      rescue => e
        # Log error but don't crash
        RubyLLM.logger&.debug "Error checking if file is binary: #{e.message}"
        false
      end
    end
  end
end