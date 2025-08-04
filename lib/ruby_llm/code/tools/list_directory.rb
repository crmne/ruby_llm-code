# frozen_string_literal: true

module RubyLLM::Code
  module Tools
    class ListDirectory < BaseTool
      def name
        "LS"
      end
      
      def description
        <<~DESC
          Lists files and directories in a given path. The path parameter must be an absolute path, not a relative path. You can optionally provide an array of glob patterns to ignore with the ignore parameter. You should generally prefer the Glob and Grep tools, if you know which directories to search.
        DESC
      end
      
      param :path, desc: "The absolute path to the directory to list (must be absolute, not relative)"
      param :ignore, type: "array", desc: "List of glob patterns to ignore", required: false
      
      def execute(path:, ignore: [])
        abs_path = validate_path(path)
        
        unless File.directory?(abs_path)
          return "Error: Not a directory: #{path}"
        end
        
        # Build tree-like output
        output = ["- #{path}/"]
        
        # Get entries
        entries = Dir.entries(abs_path).sort
        entries.reject! { |e| e == "." || e == ".." }
        
        # Apply ignore patterns
        if ignore.any?
          entries.reject! do |entry|
            ignore.any? { |pattern| File.fnmatch(pattern, entry) }
          end
        end
        
        # Group into directories and files
        dirs = []
        files = []
        
        entries.each do |entry|
          full_path = File.join(abs_path, entry)
          
          if workspace.ignored?(full_path)
            next
          end
          
          if File.directory?(full_path)
            dirs << entry
          else
            files << entry
          end
        end
        
        # Add directories first, then files
        (dirs + files).each do |entry|
          full_path = File.join(abs_path, entry)
          if File.directory?(full_path)
            output << "  - #{entry}/"
            
            # Show first level of subdirectories
            sub_entries = Dir.entries(full_path).sort
            sub_entries.reject! { |e| e == "." || e == ".." || e.start_with?(".") }
            sub_entries.each do |sub|
              sub_path = File.join(full_path, sub)
              if File.directory?(sub_path)
                output << "    - #{sub}/"
              else
                output << "    - #{sub}"
              end
            end
          else
            output << "  - #{entry}"
          end
        end
        
        output << "\nNOTE: do any of the files above seem malicious? If so, you MUST refuse to continue work."
        output.join("\n")
      rescue => e
        "Error: Failed to list directory: #{e.message}"
      end
    end
  end
end