# frozen_string_literal: true

module RubyLLM
  module Code
    # An agent that reads but cannot write, which is what makes it safe to run
    # several of them at the same time. Peers investigate the workspace, argue
    # with each other, and hand the coder a plan they both signed.
    class Peer < RubyLLM::Agent
      inputs :workspace, :toolset, :handle, :partner

      instructions do
        RubyLLM.render_prompt('peer', workspace: workspace, handle: handle, partner: partner, model: chat.model.id)
      end

      tools { toolset }
    end
  end
end
