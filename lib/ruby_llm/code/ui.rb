# frozen_string_literal: true

require 'io/console'
require 'reline'
require 'lipgloss'
require 'glamour'

module RubyLLM
  module Code
    # Everything the developer sees, in one place.
    #
    # Lipgloss draws the frames, badges, and tables; Glamour renders the
    # markdown the models write. Every write goes through one mutex, so a
    # spinner ticking in its own thread never lands in the middle of a sentence.
    class UI
      RUBY = '#CC342D'
      VIOLET = '#7D56F4'
      TEAL = '#00B8A9'
      AMBER = '#E5A50A'

      # Badge colors, in the order agents join a collaboration.
      AGENT_COLORS = [VIOLET, TEAL].freeze

      # Widest line we render, however wide the terminal is.
      MAX_WIDTH = 100

      def initialize(out: $stdout, input: $stdin, color: nil)
        @out = out
        @input = input
        @color = color.nil? ? out.tty? : color
        @mutex = Mutex.new
      end

      def color? = @color

      def width
        columns = (@out.tty? && @out.winsize[1]) || ENV['COLUMNS'].to_i
        columns.zero? ? 80 : [columns, MAX_WIDTH].min
      rescue IOError, Errno::ENOTTY, NotImplementedError
        80
      end

      def write(text) = @mutex.synchronize { @out.print(text) }
      def say(text = '') = write("#{text}\n")
      def overwrite(text) = write("\r\e[2K#{text}")
      def erase_line = write("\r\e[2K")

      # Redraws a block of lines in place, over the +replace+ lines above.
      def redraw(lines, replace: 0)
        write("#{"\e[#{replace}F" if replace.positive?}#{lines.map { |line| "\e[2K#{line}\n" }.join}")
      end

      def dim(text) = paint(text, :dim)
      def note(text) = say(dim("  #{text}"))
      def warn(text) = say("#{paint('!', :amber)} #{text}")
      def error(text) = say("#{paint('✗', :error)} #{paint(text.to_s, :error)}")
      def badge(text, color) = color? ? badge_style(color).render(" #{text} ") : " #{text} "

      # Markdown with a blank line after it, so consecutive blocks read as
      # paragraphs rather than one wall of text.
      def markdown(text) = say("#{render(text, width - 2)}\n")

      def rule(label = nil)
        line = '─' * [width - (label ? label.length + 3 : 0), 3].max
        say(dim(label ? "#{label} #{line}" : line))
      end

      def truncate(text, limit = width)
        flat = text.to_s.tr("\n", ' ')
        flat.length > limit ? "#{flat[0, [limit - 1, 1].max]}…" : flat
      end

      def table(headers, rows)
        pad = ->(cells) { cells.map { |cell| " #{cell} " } }
        say(Lipgloss::Table.new
                           .headers(pad[headers])
                           .rows(rows.map { |row| pad[row.map(&:to_s)] })
                           .border(:rounded).render)
      end

      def banner(model:, workspace:, partner: nil)
        where = [workspace.relative_home, workspace.branch].compact.join(' · ')
        lines = ["#{paint('RubyLLM Code', :title)} #{dim(VERSION)}  #{paint(model, :accent)}",
                 dim(truncate(where, width - 8))]
        lines << "#{badge('collab', TEAL)} #{dim("with #{partner}")}" if partner
        lines << dim('/help for commands · /collab <model> to pair up')
        say(paint(lines.join("\n"), :frame))
        say
      end

      # Reads a line from the developer, with history and completion. Returns
      # nil at end of input.
      def ask_user = Reline.readline(color? ? "#{paint('❯', :accent)} " : '> ', true)

      def completions=(candidates)
        Reline.completion_proc = ->(word) { candidates.grep(/\A#{Regexp.escape(word)}/) }
      end

      def tool_call(call) = say("#{paint('⏺', :accent)} #{truncate(Tools.label(call), width - 2)}")

      def tool_result(result)
        failed = result.is_a?(Hash) && result.key?(:error)
        lines = (failed ? result[:error].to_s : result.to_s).lines
        summary = lines.first.to_s.strip
        summary = "#{summary} … +#{lines.size - 1} more" if lines.size > 1
        say(paint("  ↳ #{truncate(summary, width - 6)}", failed ? :error : :dim))
      end

      # An agent's contribution, badged and set off by a colored margin.
      def agent_block(handle:, model:, color:, text:)
        say
        say("#{badge(handle, color)} #{dim(model)}")
        say(color? ? margin_style(color).render(render(text, width - 4)) : render(text, width - 4))
      end

      def spinner(label) = Spinner.new(self, label).start
      def board(rows) = Board.new(self, rows)
      def markdown_stream = Markdown.new(self)

      # Asks the developer to approve a tool call. Returns :yes, :no, or
      # :always. Without a terminal there is nobody to ask, so it says no.
      def approval(call)
        say
        say("#{paint('⏵', :amber)} #{truncate(Tools.label(call), width - 2)}")
        preview = Tools.preview(call)
        markdown(preview) if preview

        @input.tty? ? answer : refuse_without_tty
      end

      private

      def answer
        write("#{dim('  approve?')} #{paint('[y]', :accent)}es #{paint('[n]', :accent)}o " \
              "#{paint('[a]', :accent)}lways ")
        case @input.gets.to_s.strip.downcase
        when 'y', 'yes', '' then :yes
        when 'a', 'all', 'always' then :always
        else :no
        end
      end

      def refuse_without_tty
        note('no terminal to ask, so denying: pass --yolo to approve everything')
        :no
      end

      def paint(text, style) = color? ? styles.fetch(style).render(text) : text

      # Glamour pads every line out to the wrap width. Strip that, so text can
      # sit inside a border without dragging whitespace along behind it.
      def render(text, wrap)
        Glamour.render(text.to_s, style: color? ? 'auto' : 'notty', width: wrap)
               .sub(/\A\n+/, '')
               .lines.map { |line| line.sub(/(?:\e\[[\d;]*m|[ \t])+\n?\z/) { |tail| tail.delete(" \t") } }
               .join.rstrip
      end

      def styles
        @styles ||= {
          dim: Lipgloss::Style.new.foreground(Lipgloss::AdaptiveColor.new(light: '#7A7A7A', dark: '#8C8C8C')),
          accent: Lipgloss::Style.new.foreground(VIOLET).bold(true),
          title: Lipgloss::Style.new.foreground(RUBY).bold(true),
          amber: Lipgloss::Style.new.foreground(AMBER).bold(true),
          error: Lipgloss::Style.new.foreground(RUBY),
          frame: Lipgloss::Style.new.border(:rounded).border_foreground(VIOLET).padding(0, 2)
        }
      end

      def badge_style(color)
        (@badge_styles ||= {})[color] ||= Lipgloss::Style.new.bold(true).foreground('#FFFFFF').background(color)
      end

      def margin_style(color)
        (@margin_styles ||= {})[color] ||=
          Lipgloss::Style.new.border(:thick).border_top(false).border_right(false).border_bottom(false)
                         .border_left_foreground(color).padding_left(1)
      end
    end
  end
end
