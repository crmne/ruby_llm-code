# frozen_string_literal: true

module RubyLLM
  module Code
    # rubocop:disable Style/Documentation
    class InteractiveCLI
      def initialize(config)
        @config = config
        @running = true
        @conversation = ConversationManager.new(config)
        @context_manager = ContextManager.new(config)
        @command_processor = CommandProcessor.new(config, @conversation)
        @message_handler = MessageHandler.new(config, @conversation, @context_manager)

        setup_readline
      end

      def run
        display_welcome
        setup_signal_handlers

        while @running
          begin
            input = get_input
            break unless input

            process_input(input)
          rescue StandardError => e
            puts "\nError: #{e.message}"
            puts e.backtrace.first(3) if ENV['DEBUG']
          end
        end

        puts
        puts Colors.dim('● Goodbye!')
        puts
      end

      private

      def setup_readline
        return unless defined?(Readline)

        Readline.completion_append_character = ' '
        Readline.completion_proc = proc do |input|
          commands = %w[/help /quit /exit /clear /model /models /save /load /memory /tools /mcp]
          commands.grep(/^#{Regexp.escape(input)}/)
        end
      end

      def setup_signal_handlers
        trap('INT') do
          puts "\nUse /quit to exit"
        end
      end

      def display_welcome
        puts Colors.colorize('RubyLLM Code', Colors::BOLD)
        puts "Model: #{Colors.model(@config.model)}"
        puts Colors.dim('Type /help for commands')
      end

      def get_input # rubocop:disable Naming/AccessorMethodName
        puts
        prompt = Colors.prompt('> ')

        if defined?(Readline)
          Readline.readline(prompt, true)
        else
          print prompt
          gets&.chomp
        end
      end

      def process_input(input)
        return if input.strip.empty?

        if input.start_with?('/')
          result = @command_processor.process(input)
          @running = false if result == :exit
        else
          @message_handler.handle(input)
        end
      end
    end
    # rubocop:enable Style/Documentation
  end
end
