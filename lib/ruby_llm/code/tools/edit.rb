# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # Replaces one exact string with another. Ambiguity is an error, not a
      # guess: if the old text appears twice, the model has to say which one.
      class Edit < Base
        requires_approval

        description <<~TEXT
          Replace an exact string in a file. old_string must appear exactly once,
          so include enough surrounding lines to make it unique, or pass
          replace_all to change every occurrence. Read the file first.
        TEXT

        parameter :path, description: 'Path to the file, relative to the workspace root'
        parameter :old_string, description: 'The exact text to replace, including indentation'
        parameter :new_string, description: 'The text to put in its place'
        parameter :replace_all, type: :boolean, required: false,
                                description: 'Replace every occurrence instead of requiring a unique match'

        def self.label(arguments) = arguments[:path]

        def self.preview(arguments)
          removed = arguments[:old_string].to_s.lines.map { |line| "-#{line.chomp}" }
          added = arguments[:new_string].to_s.lines.map { |line| "+#{line.chomp}" }
          fence((removed + added).join("\n"), 'diff')
        end

        def execute(path:, old_string:, new_string:, replace_all: false)
          file = workspace.resolve(path)
          return { error: "#{path} does not exist" } unless file.file?

          content = file.read
          occurrences = content.scan(old_string).size
          return { error: "old_string not found in #{path}" } if occurrences.zero?
          if occurrences > 1 && !replace_all
            return { error: "old_string appears #{occurrences} times in #{path}: add context or pass replace_all" }
          end

          file.write(replace_all ? content.gsub(old_string) { new_string } : content.sub(old_string) { new_string })
          "Edited #{workspace.relative(file)} (#{replace_all ? occurrences : 1} replacement)"
        end
      end
    end
  end
end
