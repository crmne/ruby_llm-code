# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # Shared behaviour for every tool: a short model-facing name, a Workspace
      # to resolve paths against, and one place where refusals turn into
      # something the model can read and correct.
      class Base < RubyLLM::Tool
        # Tools live under RubyLLM::Code::Tools, but the model should just see
        # +read+, not the whole namespace.
        def self.tool_name = RubyLLM::Utils.underscore(name.split('::').last)

        # What goes inside the parentheses when a call to this tool is shown.
        def self.label(_arguments) = nil

        # Markdown showing what this call would do, for the approval prompt.
        # Tools that only look at things have nothing to preview.
        def self.preview(_arguments) = nil

        # A fenced markdown code block, which is how previews render.
        def self.fence(body, language = '') = "```#{language}\n#{body.to_s.rstrip}\n```"

        attr_reader :workspace

        def initialize(workspace:)
          super()
          @workspace = workspace
        end

        # Runs the tool body, turning a refusal into an error the model sees.
        def call(...)
          super
        rescue ToolError => e
          { error: e.message }
        end

        private

        # Truncates +text+ to +limit+ characters, saying how much was cut.
        def clamp(text, limit)
          return text if text.length <= limit

          "#{text[0, limit]}\n... truncated #{text.length - limit} more characters"
        end
      end
    end
  end
end
