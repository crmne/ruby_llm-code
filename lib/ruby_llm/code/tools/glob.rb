# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # rubocop:disable Style/Documentation
      class Glob < BaseTool
        def name
          'Glob'
        end

        def description
          <<~DESC
            - Fast file pattern matching tool that works with any codebase size
            - Supports glob patterns like "**/*.js" or "src/**/*.ts"
            - Returns matching file paths sorted by modification time
            - Use this tool when you need to find files by name patterns
            - When you are doing an open ended search that may require multiple rounds of globbing and grepping, use the Agent tool instead
            - You have the capability to call multiple tools in a single response. It is always better to speculatively perform multiple searches as a batch that are potentially useful.
          DESC
        end

        param :pattern, desc: 'The glob pattern to match files against'
        param :path,
              desc: 'The directory to search in. If not specified, the current working directory will be used. IMPORTANT: Omit this field to use the default directory. DO NOT enter "undefined" or "null" - simply omit it for the default behavior. Must be a valid directory path if provided.', required: false # rubocop:disable Layout/LineLength

        def execute(pattern:, path: nil) # rubocop:disable Metrics/PerceivedComplexity
          abs_path = path ? validate_path(path) : workspace.root

          return "Error: Not a directory: #{path || '.'}" unless File.directory?(abs_path)

          # Change to the search directory for glob
          matches = Dir.chdir(abs_path) do
            Dir.glob(pattern).select { |f| File.file?(f) }
          end

          # Filter ignored files
          matches.reject! { |f| workspace.ignored?(File.join(abs_path, f)) }

          # Sort by modification time (newest first)
          matches.sort_by! { |f| -File.mtime(File.join(abs_path, f)).to_i }

          # Return file paths, one per line
          if matches.empty?
            "No files found matching pattern: #{pattern}"
          else
            matches.join("\n")
          end
        rescue StandardError => e
          "Error: Glob failed: #{e.message}"
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
