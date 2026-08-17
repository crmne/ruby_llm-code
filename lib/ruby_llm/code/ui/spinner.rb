# frozen_string_literal: true

module RubyLLM
  module Code
    class UI
      # One line that keeps moving while a model thinks, and disappears without
      # a trace the moment it has something to say.
      class Spinner
        FRAMES = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
        INTERVAL = 0.08

        attr_accessor :label

        def initialize(ui, label)
          @ui = ui
          @label = label
          @started = Time.now
        end

        def start
          @thread ||= Thread.new { spin } if @ui.color?
          self
        end

        # Clears the line and stops the animation. Safe to call twice.
        def stop
          return self unless @thread

          @stopping = true
          @thread.join
          @thread = nil
          @ui.erase_line
          self
        end

        private

        def spin
          FRAMES.cycle do |frame|
            break if @stopping

            @ui.overwrite("#{@ui.dim(frame)} #{@ui.dim(label)}#{@ui.dim(elapsed)}")
            sleep INTERVAL
          end
        end

        def elapsed
          seconds = (Time.now - @started).to_i
          seconds < 2 ? '' : " (#{seconds}s)"
        end
      end
    end
  end
end
