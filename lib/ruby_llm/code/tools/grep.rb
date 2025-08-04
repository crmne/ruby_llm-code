# frozen_string_literal: true

require "shellwords"

module RubyLLM::Code
  module Tools
    class Grep < BaseTool
      def name
        "Grep"
      end
      
      def description
        <<~DESC
          A powerful search tool built on ripgrep

          Usage:
          - ALWAYS use Grep for search tasks. NEVER invoke `grep` or `rg` as a Bash command. The Grep tool has been optimized for correct permissions and access.
          - Supports full regex syntax (e.g., "log.*Error", "function\\s+\\w+")
          - Filter files with glob parameter (e.g., "*.js", "**/*.tsx") or type parameter (e.g., "js", "py", "rust")
          - Output modes: "content" shows matching lines, "files_with_matches" shows only file paths (default), "count" shows match counts
          - Use Task tool for open-ended searches requiring multiple rounds
          - Pattern syntax: Uses ripgrep (not grep) - literal braces need escaping (use `interface\\{\\}` to find `interface{}` in Go code)
          - Multiline matching: By default patterns match within single lines only. For cross-line patterns like `struct \\{[\\s\\S]*?field`, use `multiline: true`
        DESC
      end
      
      param :pattern, desc: "The regular expression pattern to search for in file contents"
      param :path, desc: "File or directory to search in (rg PATH). Defaults to current working directory.", required: false
      param :glob, desc: 'Glob pattern to filter files (e.g. "*.js", "*.{ts,tsx}") - maps to rg --glob', required: false
      param :type, desc: "File type to search (rg --type). Common types: js, py, rust, go, java, etc. More efficient than include for standard file types.", required: false
      param :output_mode, desc: 'Output mode: "content" shows matching lines (supports -A/-B/-C context, -n line numbers, head_limit), "files_with_matches" shows file paths (supports head_limit), "count" shows match counts (supports head_limit). Defaults to "files_with_matches".', required: false
      param :"-A", type: "integer", desc: 'Number of lines to show after each match (rg -A). Requires output_mode: "content", ignored otherwise.', required: false
      param :"-B", type: "integer", desc: 'Number of lines to show before each match (rg -B). Requires output_mode: "content", ignored otherwise.', required: false
      param :"-C", type: "integer", desc: 'Number of lines to show before and after each match (rg -C). Requires output_mode: "content", ignored otherwise.', required: false
      param :"-i", desc: "Case insensitive search (rg -i)", required: false
      param :"-n", desc: 'Show line numbers in output (rg -n). Requires output_mode: "content", ignored otherwise.', required: false
      param :multiline, desc: "Enable multiline mode where . matches newlines and patterns can span lines (rg -U --multiline-dotall). Default: false.", required: false
      param :head_limit, type: "integer", desc: 'Limit output to first N lines/entries, equivalent to "| head -N". Works across all output modes: content (limits output lines), files_with_matches (limits file paths), count (limits count entries). When unspecified, shows all results from ripgrep.', required: false
      
      def execute(pattern:, path: nil, **options)
        # Build ripgrep command
        cmd = ["rg"]
        
        # Add pattern (escape it for shell)
        cmd << pattern.shellescape
        
        # Add path if specified
        abs_path = path ? validate_path(path) : workspace.root
        cmd << abs_path.shellescape
        
        # Handle output mode
        output_mode = options[:output_mode] || "files_with_matches"
        
        case output_mode
        when "files_with_matches"
          cmd << "--files-with-matches"
        when "count"
          cmd << "--count"
        when "content"
          # Add context flags if specified
          cmd << "-A" << options[:"-A"].to_s if options[:"-A"]
          cmd << "-B" << options[:"-B"].to_s if options[:"-B"]
          cmd << "-C" << options[:"-C"].to_s if options[:"-C"]
          cmd << "-n" if options[:"-n"]
        end
        
        # Add other flags
        cmd << "-i" if options[:"-i"]
        cmd << "-U" << "--multiline-dotall" if options[:multiline]
        cmd << "--glob" << options[:glob] if options[:glob]
        cmd << "--type" << options[:type] if options[:type]
        
        # Execute ripgrep
        result = `#{cmd.join(' ')} 2>&1`
        exit_code = $?.exitstatus
        
        # Handle errors
        if exit_code == 2
          return "Error: #{result}"
        elsif exit_code == 1
          return "No matches found"
        end
        
        # Apply head limit if specified
        if options[:head_limit]
          lines = result.lines
          result = lines.take(options[:head_limit].to_i).join
        end
        
        result.strip
      end
    end
  end
end