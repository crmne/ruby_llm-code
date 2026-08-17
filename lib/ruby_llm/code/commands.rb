# frozen_string_literal: true

module RubyLLM
  module Code
    # The slash commands. Everything the developer can do to the session that is
    # not asking it a question.
    class Commands
      NAMES = %w[/help /model /collab /tools /cost /diff /clear /yolo /exit].freeze

      HELP = <<~MARKDOWN
        - `/model [id]` — show the model, or switch to another one
        - `/collab [id] [rounds]` — put a second model on every task, or turn it off
        - `/tools` — the tools the agent has, and which ones ask first
        - `/cost` — tokens and dollars so far
        - `/diff` — what has changed in the working tree
        - `/clear` — forget the conversation, keep the setup
        - `/yolo` — approve every tool call from here on
        - `/exit` — leave
      MARKDOWN

      def initialize(session)
        @session = session
        @ui = session.ui
      end

      # Runs one command line. Returns :exit to end the session.
      def run(line)
        name, argument = line.delete_prefix('/').split(/\s+/, 2)

        case name
        when 'help' then ui.markdown(HELP)
        when 'model' then model(argument)
        when 'collab' then collab(argument)
        when 'tools' then tools
        when 'cost' then cost
        when 'diff' then diff
        when 'clear' then clear
        when 'yolo' then yolo
        when 'exit', 'quit' then :exit
        else ui.warn("no such command: /#{name} · /help lists them")
        end
      rescue RubyLLM::ModelNotFoundError, RubyLLM::ConfigurationError => e
        ui.error(e.message)
      end

      private

      attr_reader :session, :ui

      def model(id)
        session.model = id if id
        ui.note("model · #{session.coder.model.id}")
      end

      def collab(argument)
        id, rounds = argument.to_s.split(/\s+/)
        return stop_collab if id.nil? || %w[off none stop].include?(id)

        session.pair_with(id, rounds: (rounds || session.config.rounds).to_i)
        ui.note("collab · #{session.coder.model.id} + #{id} · #{session.collab.rounds} rounds")
      end

      def stop_collab
        return ui.note('collab · off · /collab <model> to pair up') unless session.collab

        session.pair_with(nil)
        ui.note('collab · off')
      end

      def tools
        rows = session.coder.tools.values.map do |tool|
          [tool.name,
           tool.requires_approval? ? 'asks first' : 'runs',
           ui.truncate(tool.class.description.lines.first.strip, 44)]
        end
        ui.table(%w[tool approval what], rows)
      end

      def cost
        rows = session.chats.map do |who, chat|
          [who, chat.model.id, chat.tokens.input.to_i, chat.tokens.output.to_i,
           format('$%.4f', chat.cost.total.to_f)]
        end
        ui.table(%w[who model in out cost], rows)
      end

      def diff
        changes = session.workspace.diff.strip
        changes.empty? ? ui.note('nothing changed') : ui.markdown("```diff\n#{changes}\n```")
      end

      def clear
        session.reset
        ui.note('cleared')
      end

      def yolo
        session.config.yolo = !session.config.yolo
        ui.note("yolo · #{session.config.yolo ? 'on, nothing will ask' : 'off'}")
      end
    end
  end
end
