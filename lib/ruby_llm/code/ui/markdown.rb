# frozen_string_literal: true

module RubyLLM
  module Code
    class UI
      # Markdown, rendered while it streams.
      #
      # Glamour needs a whole document to render one, and a model's answer
      # arrives a few characters at a time. So this buffers the stream and
      # renders each block the moment it is finished: a paragraph when the blank
      # line after it arrives, a code block when its closing fence does. The
      # developer sees prose appear as prose and code appear highlighted,
      # without waiting for the last token.
      class Markdown
        FENCES = ['```', '~~~'].freeze

        def initialize(ui)
          @ui = ui
          @buffer = +''
        end

        # Adds streamed text and prints whatever is now complete.
        def <<(text)
          return self if text.nil? || text.empty?

          @buffer << text
          while (boundary = complete_block)
            emit(@buffer.slice!(0, boundary))
          end
          self
        end

        # Prints everything buffered, finished or not.
        def flush
          emit(@buffer.slice!(0, @buffer.length))
          self
        end
        alias close flush

        private

        # The length of the leading block, once there is one: text up to and
        # including the blank line that ends it, or a closed fence.
        def complete_block
          fenced = false
          offset = 0

          @buffer.each_line do |line|
            offset += line.length
            if line.start_with?(*FENCES)
              fenced = !fenced
              return offset unless fenced
            elsif !fenced && line.strip.empty?
              return offset
            end
          end

          nil
        end

        def emit(block)
          return if block.nil? || block.strip.empty?

          @ui.markdown(block)
        end
      end
    end
  end
end
