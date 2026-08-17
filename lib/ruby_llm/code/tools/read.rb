# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # Reads a file back with line numbers, which is what makes edits precise.
      class Read < Base
        description <<~TEXT
          Read a file from the workspace. Returns the contents with line numbers,
          so you can quote exact lines when editing. Use offset and limit to walk
          through a long file instead of pulling all of it into context.
        TEXT

        parameter :path, description: 'Path to the file, relative to the workspace root'
        parameter :offset, type: :integer, required: false, description: 'First line to read, 1-based'
        parameter :limit, type: :integer, required: false, description: 'How many lines to read'

        def self.label(arguments) = arguments[:path]

        def execute(path:, offset: nil, limit: nil)
          file = workspace.resolve(path)
          return { error: "#{path} does not exist" } unless file.exist?
          return { error: "#{path} is a directory: use list" } if file.directory?

          content = file.read(Workspace::MAX_READ_BYTES)
          return { error: "#{path} looks binary" } if content.include?("\x00")

          lines = content.lines
          first = [offset.to_i, 1].max
          window = lines.drop(first - 1)
          window = window.first(limit.to_i) if limit.to_i.positive?

          "#{header(file, lines, first, window)}\n#{number(window, first)}".rstrip
        end

        private

        def number(window, first)
          window.each_with_index.map { |line, index| format("%<n>6d\t%<line>s", n: first + index, line: line) }.join
        end

        def header(file, lines, first, window)
          span = if window.size == lines.size
                   "#{lines.size} lines"
                 else
                   "lines #{first}-#{first + window.size - 1} of #{lines.size}"
                 end
          span += ', file truncated' if file.size > Workspace::MAX_READ_BYTES
          "#{workspace.relative(file)} (#{span})"
        end
      end
    end
  end
end
