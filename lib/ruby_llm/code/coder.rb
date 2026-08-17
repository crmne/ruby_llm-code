# frozen_string_literal: true

module RubyLLM
  module Code
    # The agent that changes things: full toolset, the developer's workspace,
    # and instructions rendered from prompts/coder.txt.erb with the facts of
    # where it is standing.
    class Coder < RubyLLM::Agent
      inputs :workspace, :toolset

      instructions { RubyLLM.render_prompt('coder', workspace: workspace) }
      tools { toolset }
    end
  end
end
