# frozen_string_literal: true

require 'fileutils'

module RubyLLM
  module Code
    module Tools
      # Writes a whole file. Needs a yes, because it replaces what was there.
      class Write < Base
        requires_approval

        description <<~TEXT
          Write a file in the workspace, creating parent directories as needed and
          replacing the file completely if it already exists. Read a file before
          overwriting it. For a small change to a big file, prefer edit.
        TEXT

        parameter :path, description: 'Path to the file, relative to the workspace root'
        parameter :content, description: 'The complete contents to write'

        PREVIEW_LINES = 24

        def self.label(arguments) = arguments[:path]

        def self.preview(arguments)
          lines = arguments[:content].to_s.lines
          body = lines.first(PREVIEW_LINES).join
          body += "... #{lines.size - PREVIEW_LINES} more lines\n" if lines.size > PREVIEW_LINES
          fence(body, File.extname(arguments[:path].to_s).delete('.'))
        end

        def execute(path:, content:)
          file = workspace.resolve(path)
          existed = file.file?
          FileUtils.mkdir_p(file.dirname)
          file.write(content.to_s)

          "#{existed ? 'Updated' : 'Created'} #{workspace.relative(file)} " \
            "(#{content.to_s.lines.size} lines, #{content.to_s.bytesize} bytes)"
        end
      end
    end
  end
end
