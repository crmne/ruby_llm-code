# frozen_string_literal: true

module RubyLLM
  module Code
    module Tools
      # rubocop:disable Style/Documentation
      class ExitPlanMode < BaseTool
        def name
          'ExitPlanMode'
        end

        description <<~DESC
          Use this tool when you are in plan mode and have finished presenting your plan and are ready to code. This will prompt the user to exit plan mode.#{' '}
          IMPORTANT: Only use this tool when the task requires planning the implementation steps of a task that requires writing code. For research tasks where you're gathering information, searching files, reading files or in general trying to understand the codebase - do NOT use this tool.

          Eg.#{' '}
          1. Initial task: "Search for and understand the implementation of vim mode in the codebase" - Do not use the exit plan mode tool because you are not planning the implementation steps of a task.
          2. Initial task: "Help me implement yank mode for vim" - Use the exit plan mode tool after you have finished planning the implementation steps of the task.
        DESC

        param :plan,
              desc: 'The plan you came up with, that you want to run by the user for approval. Supports markdown. The plan should be pretty concise.' # rubocop:disable Layout/LineLength

        def execute(plan:)
          # Display the plan in a formatted way
          <<~PLAN

            ## Implementation Plan

            #{plan}

            ---
            Ready to proceed with implementation? (Type 'yes' to continue or provide feedback)
          PLAN
        end
      end
      # rubocop:enable Style/Documentation
    end
  end
end
