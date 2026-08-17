# frozen_string_literal: true

require 'optparse'

module RubyLLM
  module Code
    # The command line: flags, a piped-in file or two, and then either one
    # question or the whole REPL.
    class CLI
      BANNER = <<~USAGE
        Usage: rubyllm [options] [question]

            rubyllm                              start a session
            rubyllm "why is this test flaky?"    ask once and leave
            cat error.log | rubyllm "fix this"   pipe something in
      USAGE

      def self.start(argv = ARGV)
        new(argv).run
      end

      def initialize(argv)
        @options = {}
        @question = parser.parse!(argv).join(' ')
      end

      def run
        config = Config.new(**@options).apply!
        session = Session.new(config: config)
        question = [@question, piped_input].compact.join("\n\n")

        question.empty? ? session.repl : session.ask(question)
      rescue RubyLLM::ConfigurationError => e
        abort "#{e.message.lines.first.strip} Export one of #{Config::DEFAULT_MODELS.keys.join(', ')}, " \
              'or point --model at a provider you have a key for.'
      rescue Error, RubyLLM::ModelNotFoundError => e
        abort e.message
      end

      private

      def parser
        OptionParser.new do |opts|
          opts.banner = BANNER
          opts.separator "\nOptions:"
          opts.on('-m', '--model ID', 'model to answer with') { |id| @options[:model] = id }
          opts.on('-c', '--collab ID', 'second model to collaborate with') { |id| @options[:partner_model] = id }
          opts.on('-r', '--rounds N', Integer, 'rounds of collaboration') { |n| @options[:rounds] = n }
          opts.on('-C', '--dir DIR', 'workspace to work in') { |dir| @options[:workspace_dir] = dir }
          opts.on('-y', '--yolo', 'approve every tool call') { @options[:yolo] = true }
          opts.on('-v', '--version', 'print the version') { exit_with(VERSION) }
          opts.on('-h', '--help', 'print this') { exit_with(opts) }
        end
      end

      def piped_input
        $stdin.read unless $stdin.tty?
      end

      def exit_with(message)
        puts message
        exit
      end
    end
  end
end
