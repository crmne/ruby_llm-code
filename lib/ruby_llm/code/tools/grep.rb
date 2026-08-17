# frozen_string_literal: true

require 'open3'

module RubyLLM
  module Code
    module Tools
      # Searches file contents. Uses ripgrep when it is installed and falls back
      # to Ruby so the tool works on a bare machine.
      class Grep < Base
        LIMIT = 100
        MAX_OUTPUT = 20_000

        description <<~TEXT
          Search file contents with a regular expression and return matching lines
          with their file and line number. Narrow the search with path or glob.
        TEXT

        parameter :pattern, description: 'Regular expression to search for'
        parameter :path, required: false, description: 'File or directory to search under. Defaults to the workspace'
        parameter :glob, required: false, description: 'Only search files matching this glob, for example "*.rb"'
        parameter :ignore_case, type: :boolean, required: false, description: 'Match without regard to case'

        def self.label(arguments) = [arguments[:pattern], arguments[:path]].compact.join(' in ')

        def execute(pattern:, path: '.', glob: nil, ignore_case: false)
          target = workspace.resolve(path)
          return { error: "#{path} does not exist" } unless target.exist?

          matches = ripgrep(pattern, target, glob, ignore_case) || search(pattern, target, glob, ignore_case)
          return "No matches for #{pattern}" if matches.empty?

          shown = matches.first(LIMIT).join("\n")
          shown += "\n... #{matches.size - LIMIT} more matches" if matches.size > LIMIT
          clamp(shown, MAX_OUTPUT)
        rescue RegexpError => e
          { error: "invalid pattern: #{e.message}" }
        end

        private

        def ripgrep(pattern, target, glob, ignore_case)
          command = ['rg', '--line-number', '--no-heading', '--color', 'never']
          command << '--ignore-case' if ignore_case
          command += ['--glob', glob] if glob
          Workspace::NOISE.each { |name| command += ['--glob', "!#{name}/"] }
          command += ['--regexp', pattern.to_s, target.to_s]

          stdout, status = Open3.capture2(*command, chdir: workspace.root.to_s)
          return [] if status.exitstatus == 1 # ripgrep found nothing

          status.success? ? stdout.lines(chomp: true).map { |line| line.delete_prefix("#{workspace.root}/") } : nil
        rescue Errno::ENOENT
          nil # no ripgrep here, fall back to Ruby
        end

        def search(pattern, target, glob, ignore_case)
          regexp = Regexp.new(pattern.to_s, ignore_case ? Regexp::IGNORECASE : nil)
          candidates(target, glob).flat_map { |file| matching_lines(file, regexp) }
        end

        def candidates(target, glob)
          target.file? ? [target] : workspace.files(glob || '**/*', base: target)
        end

        def matching_lines(file, regexp)
          file.each_line.with_index(1).filter_map do |line, number|
            "#{workspace.relative(file)}:#{number}:#{line.chomp}" if regexp.match?(line)
          end
        rescue ArgumentError, SystemCallError
          [] # unreadable or not text
        end
      end
    end
  end
end
