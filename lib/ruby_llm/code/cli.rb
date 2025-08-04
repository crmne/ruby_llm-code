# frozen_string_literal: true

module RubyLLM
  module Code
    # rubocop:disable Style/Documentation
    class CLI
      def self.run!(argv = ARGV)
        new.run(argv)
      end

      def self.start(argv)
        run!(argv)
      end

      def initialize
        @config = Config.new
        @interactive = true
        @input_text = nil
        @non_interactive = false
        @stream = true
      end

      def run(argv)
        parse_options(argv)

        if @non_interactive || @input_text || !$stdin.tty?
          NonInteractiveCLI.new(@config, stream: @stream).run(@input_text || $stdin.read)
        else
          InteractiveCLI.new(@config).run
        end
      rescue Interrupt
        puts "\nExiting..."
        exit(0)
      rescue StandardError => e
        warn "Error: #{e.message}"
        warn e.backtrace if ENV['DEBUG']
        exit(1)
      end

      private

      def parse_options(argv)
        parser = OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
          opts.banner = 'Usage: rubyllm [options] [prompt]'

          opts.on('-m', '--model MODEL', 'Specify AI model') do |m|
            @config.model = m
          end

          opts.on('-s', '--system PROMPT', 'System prompt') do |s|
            @config.system_prompt = s
          end

          opts.on('-t', '--temperature TEMP', Float, 'Temperature (0.0-2.0)') do |t|
            @config.temperature = t
          end

          opts.on('--no-stream', 'Disable streaming') do
            @stream = false
          end

          opts.on('-n', '--non-interactive', 'Non-interactive mode') do
            @non_interactive = true
          end

          opts.on('--config FILE', 'Config file path') do |f|
            @config.load_file(f)
          end

          opts.on('-h', '--help', 'Show help') do
            puts opts
            exit(0)
          end

          opts.on('-v', '--version', 'Show version') do
            puts "RubyLLM Code v#{RubyLLM::Code::VERSION}"
            exit(0)
          end
        end

        parser.parse!(argv)
        @input_text = argv.join(' ') unless argv.empty?
      end
    end
    # rubocop:enable Style/Documentation
  end
end
