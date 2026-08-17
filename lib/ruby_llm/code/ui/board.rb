# frozen_string_literal: true

module RubyLLM
  module Code
    class UI
      # A handful of lines that stay put while several agents work at once, one
      # line each, redrawn in place. This is what makes the parallel phase of a
      # collaboration legible: you watch both models read your code at the same
      # time instead of guessing which one is stuck.
      class Board
        # +rows+ is one Hash per agent, with :handle, :model, and :color.
        def initialize(ui, rows)
          @ui = ui
          @rows = rows
          @status = Array.new(rows.size, 'starting')
          @frame = 0
        end

        def update(index, status)
          @status[index] = status.to_s
          @ui.color? ? draw : @ui.say("[#{@rows[index][:handle]} #{@rows[index][:model]}] #{status}")
        end

        # Advances the animation without changing what anyone is doing.
        def tick
          @frame += 1
          draw if @ui.color?
        end

        # Replaces the live lines with a final word for each agent.
        def close(status = 'done')
          @status.map! { status }
          @frame = -1
          draw if @ui.color?
        end

        private

        def draw
          @ui.redraw(@rows.each_index.map { |index| line(index) }, replace: @drawn ? @rows.size : 0)
          @drawn = true
        end

        def line(index)
          row = @rows[index]
          marker = @frame.negative? ? '✓' : Spinner::FRAMES[@frame % Spinner::FRAMES.size]
          room = [@ui.width - row[:model].length - row[:handle].length - 8, 20].max
          "#{@ui.badge(row[:handle], row[:color])} #{@ui.dim(row[:model])} " \
            "#{@ui.dim(marker)} #{@ui.dim(@ui.truncate(@status[index], room))}"
        end
      end
    end
  end
end
