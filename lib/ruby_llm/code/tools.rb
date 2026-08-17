# frozen_string_literal: true

module RubyLLM
  module Code
    # The agent's hands. Seven tools, each one thing: four that only look, and
    # three that change something and therefore ask first.
    module Tools
      # Tools that cannot change anything, so collaborating agents can all use
      # them at once without stepping on each other.
      READ_ONLY = [Read, List, Glob, Grep].freeze

      # Tools that touch the working tree or the shell. Each declares
      # requires_approval, so the agentic loop parks until you decide.
      WRITE = [Write, Edit, Shell].freeze

      class << self
        def all(workspace) = build(READ_ONLY + WRITE, workspace)
        def read_only(workspace) = build(READ_ONLY, workspace)

        # How a call reads in the transcript: <tt>read(lib/agent.rb)</tt>.
        def label(call)
          detail = ask(call, :label)
          detail.to_s.empty? ? call.name : "#{call.name}(#{detail})"
        end

        # Markdown showing what a call is about to do, or nil.
        def preview(call) = ask(call, :preview)

        private

        def build(tools, workspace) = tools.map { |tool| tool.new(workspace: workspace) }

        def ask(call, question)
          tool = (READ_ONLY + WRITE).find { |candidate| candidate.tool_name == call.name.to_s }
          tool&.public_send(question, call.arguments.to_h.transform_keys(&:to_sym))
        end
      end
    end
  end
end
