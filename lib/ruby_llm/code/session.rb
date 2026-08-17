# frozen_string_literal: true

module RubyLLM
  module Code
    # One sitting with the agent: the prompt, the turns, and the approvals.
    #
    # RubyLLM drives the agentic loop, so a turn here is `ask_later` then
    # `complete` until the chat says it is done. When the model asks for a tool
    # that needs a yes, `complete` parks and `awaiting_approval?` is true; we ask
    # the developer, record the decision, and call `complete` again.
    class Session
      attr_reader :config, :ui, :workspace, :coder, :collab

      def initialize(config:, ui: UI.new)
        @config = config
        @ui = ui
        @workspace = Workspace.new(config.workspace_dir)
        @coder = build_coder
        @collab = Collab.new(self, model: config.partner_model, rounds: config.rounds) if config.partner_model
      end

      # The read-eval-print part.
      def repl
        ui.banner(model: coder.model.id, workspace: workspace, partner: config.partner_model)
        ui.completions = Commands::NAMES

        while (line = read_line)
          next if line.empty?

          if line.start_with?('/')
            break if commands.run(line) == :exit
          else
            ask(line)
          end
        end

        ui.note(ledger)
      end

      # One turn, however this session is set up.
      def ask(task)
        collab ? collab.run(task) : run(task)
      rescue Interrupt
        ui.note('interrupted')
      rescue StandardError => e
        ui.error("#{e.class}: #{e.message}")
      end

      # Runs one prompt through the coder, streaming the answer and stopping for
      # approval when a tool needs it.
      def run(prompt)
        @stream = ui.markdown_stream
        @spinner = ui.spinner('thinking')
        coder.ask_later(prompt)

        loop do
          coder.complete { |chunk| show(chunk) }
          break unless coder.awaiting_approval?

          @spinner.stop
          @stream.flush
          coder.pending_approvals.each { |call| decide(call) }
          @spinner = ui.spinner('working')
        end
      rescue Interrupt
        settle
      rescue StandardError => e
        ui.error("#{e.class}: #{e.message}")
      ensure
        @spinner.stop
        @stream.flush
        ui.say
      end

      # Starts over, keeping the model and the collaboration setup.
      def reset = @coder = build_coder

      # Switches the model the coder answers with, from here on.
      def model=(id)
        coder.with_model(id)
      end

      # Brings a second model in, or sends it home when +model+ is nil.
      def pair_with(model, rounds: config.rounds)
        RubyLLM.models.find(model) if model
        config.partner_model = model
        config.rounds = rounds
        @collab = model && Collab.new(self, model: model, rounds: rounds)
      end

      # Every chat this session has run, by who ran it: the coder, and any
      # collaborators it called in.
      def chats
        return { 'coder' => coder } unless collab

        { 'coder' => coder }.merge(collab.participants.to_h { |peer| [peer.handle, peer.agent] })
      end

      # What this sitting has cost so far.
      def ledger
        spent = chats.each_value
        "#{spent.sum { |chat| chat.tokens.input.to_i + chat.tokens.output.to_i }} tokens · " \
          "$#{format('%.4f', spent.sum { |chat| chat.cost.total.to_f })}"
      end

      private

      def commands = @commands ||= Commands.new(self)

      def read_line
        ui.ask_user&.strip
      rescue Interrupt
        ui.note('^C · /exit to leave')
        ''
      end

      def build_coder
        Coder.new(workspace: workspace, toolset: Tools.all(workspace), model: config.model).tap do |coder|
          coder.before_tool_call { |call| announce(call) }
          coder.after_tool_result { |result| report(result) }
        end
      end

      def show(chunk)
        return if chunk.content.to_s.empty?

        @spinner.stop
        @stream << chunk.content
      end

      def announce(call)
        @spinner.stop
        @stream.flush
        ui.tool_call(call)
        @spinner = ui.spinner(call.name)
      end

      def report(result)
        @spinner.stop
        ui.tool_result(result)
        @spinner = ui.spinner('thinking')
      end

      def decide(call)
        return coder.approve!(call) if config.yolo

        case ui.approval(call)
        when :always
          config.yolo = true
          coder.approve!(call)
        when :yes then coder.approve!(call)
        else
          ui.note('denied')
          coder.deny!(call)
        end
      end

      # Ctrl-C leaves a round half finished, and the next question cannot be
      # asked until it is answered. Deny whatever was waiting and let RubyLLM
      # close the round.
      def settle
        ui.note('interrupted')
        coder.pending_approvals.each { |call| coder.deny!(call) }
        coder.run_tools
      rescue StandardError
        nil
      end
    end
  end
end
