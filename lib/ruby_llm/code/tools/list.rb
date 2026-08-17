# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # Lists a directory, minus the noise.
      class List < Base
        LIMIT = 200

        description <<~TEXT
          List the entries of a directory in the workspace. Directories end in a
          slash. Build output, dependency directories, and version control
          internals are left out.
        TEXT

        parameter :path, required: false,
                         description: 'Directory to list, relative to the workspace root. Defaults to .'

        def self.label(arguments) = arguments[:path] || '.'

        def execute(path: '.')
          directory = workspace.resolve(path)
          return { error: "#{path} does not exist" } unless directory.exist?
          return { error: "#{path} is not a directory: use read" } unless directory.directory?

          entries = directory.children.reject { |child| workspace.noise?(child) }
                             .sort_by { |child| [child.directory? ? 0 : 1, child.basename.to_s] }
          return "#{workspace.relative(directory)} is empty" if entries.empty?

          "#{workspace.relative(directory)}:\n#{listing(entries).join("\n")}"
        end

        private

        def listing(entries)
          shown = entries.first(LIMIT).map do |child|
            child.directory? ? "#{child.basename}/" : "#{child.basename} (#{child.size} bytes)"
          end
          entries.size > LIMIT ? shown + ["... #{entries.size - LIMIT} more entries"] : shown
        end
      end
    end
  end
end
