# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # Finds files by name pattern, most recently touched first, because the
      # file someone just edited is usually the one being asked about.
      class Glob < Base
        LIMIT = 200

        description <<~TEXT
          Find files by glob pattern, for example "**/*.rb" or "lib/**/*_spec.rb".
          Results come back newest first. Use grep to search inside files.
        TEXT

        parameter :pattern, description: 'Glob pattern, matched from the workspace root'

        def self.label(arguments) = arguments[:pattern]

        def execute(pattern:)
          matches = workspace.files(pattern).sort_by { |path| -path.mtime.to_f }.map { |path| workspace.relative(path) }
          return "No files match #{pattern}" if matches.empty?

          listing = matches.first(LIMIT)
          listing << "... #{matches.size - LIMIT} more matches" if matches.size > LIMIT
          listing.join("\n")
        rescue SystemCallError => e
          { error: e.message }
        end
      end
    end
  end
end
