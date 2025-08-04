# frozen_string_literal: true

module RubyLLM
  module Code
    # rubocop:disable Style/Documentation
    class MessageHandler
      def initialize(config, conversation_manager, context_manager)
        @config = config
        @conversation = conversation_manager
        @context_manager = context_manager
        @tools_used = false
      end

      def handle(message) # rubocop:disable Metrics/PerceivedComplexity
        # Check for new topic
        puts "\n[New topic detected]" if @context_manager.check_new_topic(message, recent_messages)

        # Show typing indicator
        typing_thread = start_typing_indicator

        # Send message and stream response
        response = ''
        first_content = true

        begin
          @conversation.chat.ask(message) do |chunk|
            if chunk.content && !chunk.content.empty?
              if first_content
                stop_typing_indicator(typing_thread)
                puts
                print '● '
                first_content = false
              end

              # Apply syntax highlighting to the chunk
              highlighted = SyntaxHighlighter.highlight(chunk.content)

              # Handle newlines for bullet points
              highlighted.each_char do |char|
                if char == "\n"
                  print char
                  # Check if this is a paragraph break (double newline)
                  # Only add bullet if we're at a true paragraph break
                  if response.end_with?("\n") && !response.end_with?("\n\n")
                    # Next char should also be newline for paragraph break
                    # Don't add bullet yet - wait to see if next char is newline
                  elsif response.end_with?("\n\n")
                    print '● '
                  end
                else
                  print char
                end
              end

              response += chunk.content
            end
            $stdout.flush
          end

          # Track conversation
          @conversation.add_message(role: 'user', content: message)
          @conversation.add_message(role: 'assistant', content: response)

          puts # Add single blank line after message
        rescue StandardError => e
          stop_typing_indicator(typing_thread)
          puts "\n\n#{Colors.error("● Error: #{e.message}")}"
        end
      end

      private

      def recent_messages
        @conversation.messages.last(10).map { |m| m[:content] }
      end

      def start_typing_indicator
        start_time = Time.now
        Thread.new do
          loop do
            elapsed = (Time.now - start_time).to_i
            print "\r#{Colors.dim("· Whirring… (#{elapsed}s · ↑ 0 tokens · esc to interrupt)")}"
            $stdout.flush
            sleep 0.1
          end
        end
      end

      def stop_typing_indicator(thread)
        thread.kill if thread&.alive?
        print "\r#{' ' * 50}\r" # Clear line
      end
    end
    # rubocop:enable Style/Documentation
  end
end
