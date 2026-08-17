# frozen_string_literal: true

require 'pathname'
require 'open3'

module RubyLLM
  module Code
    # The one directory the agent may touch. Every tool resolves its paths
    # through a Workspace, which keeps them inside #root and hides the noise
    # (.git, node_modules, build output) that no one wants read back to them.
    class Workspace
      # Directory names skipped when listing, globbing, and grepping.
      NOISE = %w[.git .svn .hg node_modules .bundle tmp log coverage .yardoc
                 _site dist build target .next .venv __pycache__].freeze

      # Files larger than this are truncated rather than read whole.
      MAX_READ_BYTES = 256 * 1024

      # Context files a project leaves for its agents.
      CONTEXT_FILES = %w[AGENTS.md CLAUDE.md].freeze

      attr_reader :root

      def initialize(root = Dir.pwd)
        @root = Pathname.new(File.expand_path(root.to_s))
        raise Error, "#{@root} is not a directory" unless @root.directory?
      end

      # Turns a model-supplied path into an absolute Pathname, refusing
      # anything that would climb out of the workspace.
      def resolve(path)
        raise ToolError, 'path is required' if path.nil? || path.to_s.strip.empty?

        candidate = Pathname.new(File.expand_path(path.to_s, root.to_s))
        return candidate if candidate == root || candidate.to_s.start_with?("#{root}#{File::SEPARATOR}")

        raise ToolError, "#{path} is outside the workspace (#{root})"
      end

      # The path as a human would write it: relative to the workspace root.
      def relative(path)
        Pathname.new(path.to_s).relative_path_from(root).to_s
      rescue ArgumentError
        path.to_s
      end

      # The workspace as it appears in a prompt: ~/Code/thing.
      def relative_home = root.to_s.sub(Dir.home, '~')

      # Whether the path lives somewhere nobody wants to read from.
      def noise?(path) = relative(path).split(File::SEPARATOR).any? { |segment| NOISE.include?(segment) }

      # The files matching +pattern+ under +base+, minus anything outside the
      # workspace or buried in noise. Globbing goes through here, so a pattern
      # that climbs out is caught in one place rather than in every tool.
      def files(pattern, base: root)
        Dir.glob(pattern.to_s, base: base.to_s, flags: File::FNM_DOTMATCH)
           .map { |path| base.join(path) }
           .select { |path| path.file? && inside?(path) && !noise?(path) }
      end

      def inside?(path)
        resolve(path)
        true
      rescue ToolError
        false
      end

      def git? = root.join('.git').exist?

      def branch
        return unless git?

        capture('git', 'rev-parse', '--abbrev-ref', 'HEAD').strip
      end

      # The uncommitted work, ready to show a reviewer.
      def diff
        return '' unless git?

        [capture('git', 'diff', '--stat', 'HEAD'), capture('git', 'diff', 'HEAD')].join("\n")
      end

      # The project's own instructions for agents, concatenated.
      def context
        CONTEXT_FILES.filter_map do |name|
          path = root.join(name)
          "# #{name}\n\n#{path.read.strip}" if path.file?
        end.join("\n\n")
      end

      # A short description of where we are, for the system prompt.
      def overview(limit: 40)
        entries = root.children.reject { |child| noise?(child) }
                      .sort_by { |child| [child.directory? ? 0 : 1, child.to_s] }
        listing = entries.first(limit).map { |child| child.directory? ? "#{relative(child)}/" : relative(child) }
        listing << "... #{entries.size - limit} more" if entries.size > limit
        listing.join("\n")
      end

      private

      def capture(*command)
        stdout, = Open3.capture2e(*command, chdir: root.to_s)
        stdout
      rescue StandardError => e
        "(#{e.message})"
      end
    end
  end
end
