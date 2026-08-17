# frozen_string_literal: true

require 'async'

module RubyLLM
  module Code
    # Two models, one task.
    #
    # This is the parallel workflow from the RubyLLM guides pointed at a
    # codebase. Both agents read the workspace at the same time, each one an
    # Async task, so the two conversations genuinely overlap instead of taking
    # turns. Then they answer each other until they agree, one writes the plan,
    # the coder implements it, and the other reviews the diff it produced.
    #
    # The whole turn runs inside one RubyLLM.workflow, so every model call in it
    # is correlated in instrumentation, phase by phase.
    class Collab
      # One side of the conversation: the agent, the badge it wears, the model
      # behind it, and who it is arguing with.
      Participant = Struct.new(:agent, :handle, :model, :color, :partner) do
        def name = "#{handle} (#{model})"
        def ask(prompt) = agent.ask(prompt).content
      end

      AGREED = /\A\W*AGREED\b/i
      ISSUES = /\A\W*ISSUES\b/i
      MAX_DIFF = 20_000
      TICK = 0.1

      attr_reader :session, :model, :rounds

      def initialize(session, model:, rounds: 2)
        @session = session
        @model = model
        @rounds = rounds
      end

      # One collaborative turn, from first read to reviewed diff.
      def run(task)
        RubyLLM.workflow('collab', metadata: { models: participants.map(&:model) }) do |workflow|
          replies = workflow.step('explore') { explore(task) }
          workflow.step('debate') { debate(replies) }
          plan = workflow.step('plan') { write_plan }
          workflow.step('implement') { implement(task, plan) }
          workflow.step('review') { review }
        end
      end

      def participants
        @participants ||= begin
          mine = session.coder.model.id
          [peer('A', mine, "B (#{model})", UI::AGENT_COLORS[0]), peer('B', model, "A (#{mine})", UI::AGENT_COLORS[1])]
            .each_with_index { |participant, index| watch(participant, index) }
        end
      end

      private

      def ui = session.ui
      def workspace = session.workspace

      def peer(handle, model, partner, color)
        agent = Peer.new(model: model, workspace: workspace, toolset: Tools.read_only(workspace),
                         handle: handle, partner: partner)
        Participant.new(agent, handle, model, color, partner)
      end

      # Both agents open with a proposal, at the same time.
      def explore(task)
        ui.rule('explore')
        show gather(participants.map { |peer| prompt('propose', task: task, partner: peer.partner) })
      end

      # Then they answer each other until they agree or run out of rounds.
      def debate(replies)
        rounds.times do |round|
          return replies if replies.all? { |reply| reply.match?(AGREED) }

          ui.rule("round #{round + 1}")
          replies = show gather(reactions(replies))
        end
        replies
      end

      def reactions(replies)
        participants.each_with_index.map do |peer, index|
          prompt('respond', partner: peer.partner, message: replies[index.zero? ? 1 : 0])
        end
      end

      # The agent that opened writes the plan, since it has the whole argument.
      def write_plan
        author = participants.first
        ui.rule('plan')
        plan = alone(author) { author.ask(prompt('plan', partner: author.partner)) }
        block(author, plan)
        plan
      end

      def implement(task, plan)
        ui.rule("implement · #{session.coder.model.id}")
        session.run(prompt('implement', task: task, plan: plan,
                                        models: participants.map(&:name).join(' and ')))
      end

      # The other agent reads the diff it did not write.
      def review
        diff = workspace.diff.strip
        return ui.note('nothing changed, so nothing to review') if diff.empty?

        reviewer = participants.last
        ui.rule("review · #{reviewer.model}")
        verdict = alone(reviewer) { reviewer.ask(prompt('review', diff: diff[0, MAX_DIFF])) }
        block(reviewer, verdict)

        return unless verdict.match?(ISSUES)

        ui.rule('fix')
        session.run(prompt('fix', reviewer: reviewer.name, review: verdict))
      end

      # Asks every participant at once and returns their answers in order.
      # One Async task per agent, plus one keeping the board animated.
      def gather(prompts)
        @board = ui.board(participants.map { |peer| { handle: peer.handle, model: peer.model, color: peer.color } })

        Async do |task|
          ticker = task.async do
            loop do
              @board.tick
              sleep TICK
            end
          end

          begin
            participants.each_with_index.map { |peer, index| task.async { peer.ask(prompts[index]) } }.map(&:wait)
          ensure
            ticker.stop
            @board.close
          end
        end.wait
      ensure
        @board = nil
      end

      # A phase with only one agent working gets a spinner instead of a board.
      def alone(peer)
        @spinner = ui.spinner("#{peer.handle} thinking")
        yield
      ensure
        @spinner.stop
        @spinner = nil
      end

      # Whatever a peer is reading shows up on its line of the board, or on the
      # spinner when it is working alone.
      def watch(participant, index)
        participant.agent.before_tool_call do |call|
          @board ? @board.update(index, Tools.label(call)) : @spinner&.label = Tools.label(call)
        end
      end

      def show(replies)
        participants.each_with_index { |participant, index| block(participant, replies[index]) }
        replies
      end

      def block(participant, text)
        ui.agent_block(handle: participant.handle, model: participant.model, color: participant.color, text: text)
      end

      def prompt(name, **locals) = RubyLLM.render_prompt("collab/#{name}", **locals)
    end
  end
end
