# frozen_string_literal: true

RSpec.describe RubyLLM::Code::Collab do
  subject(:collab) { described_class.new(session, model: 'gpt-5.4', rounds: 2) }

  let(:session) do
    instance_double(RubyLLM::Code::Session, ui: ui, workspace: sandbox, coder: coder, run: nil)
  end
  let(:coder) { instance_double(RubyLLM::Code::Coder, model: instance_double(RubyLLM::Model, id: 'claude-sonnet-5')) }

  # Every peer answers from a script, one reply per turn.
  def peers_reply(*scripts)
    agents = scripts.map do |script|
      replies = script.dup
      instance_double(RubyLLM::Code::Peer).tap do |agent|
        allow(agent).to receive(:before_tool_call)
        allow(agent).to receive(:ask) { RubyLLM::Message.new(role: :assistant, content: replies.shift) }
      end
    end
    allow(RubyLLM::Code::Peer).to receive(:new).and_return(*agents)
  end

  before { file('lib/thing.rb') }

  it 'introduces two agents, one per model' do
    peers_reply(['a'], ['b'])

    expect(collab.participants.map(&:model)).to eq(['claude-sonnet-5', 'gpt-5.4'])
    expect(collab.participants.map(&:handle)).to eq(%w[A B])
  end

  it 'stops debating as soon as both agree' do
    peers_reply(['AGREED: ship it', 'the plan'], ['AGREED: ship it', 'LGTM: fine'])

    collab.run('add a greeter')

    expect(collab.participants.first.agent).to have_received(:ask).twice # propose, then write the plan
  end

  it 'keeps answering until the rounds run out' do
    peers_reply(['REVISE: no', 'REVISE: still no', 'REVISE: nope', 'the plan'],
                ['REVISE: no', 'REVISE: still no', 'REVISE: nope', 'LGTM: fine'])

    collab.run('add a greeter')

    # propose, two rounds of answering back, then the plan
    expect(collab.participants.first.agent).to have_received(:ask).exactly(4).times
  end

  it 'hands the plan to the coder' do
    peers_reply(['AGREED: yes', 'Step 1. write lib/greeter.rb'], ['AGREED: yes', 'LGTM: fine'])

    collab.run('add a greeter')

    expect(session).to have_received(:run).once.with(a_string_including('Step 1. write lib/greeter.rb'))
  end

  it 'sends the review back to the coder when the reviewer finds problems' do
    allow(sandbox).to receive(:diff).and_return('diff --git a/lib/greeter.rb')
    peers_reply(['AGREED: yes', 'the plan'], ['AGREED: yes', "ISSUES:\n1. lib/greeter.rb:2 wrong name"])

    collab.run('add a greeter')

    expect(session).to have_received(:run).with(a_string_including('wrong name'))
  end

  it 'leaves the coder alone when the reviewer is happy' do
    allow(sandbox).to receive(:diff).and_return('diff --git a/lib/greeter.rb')
    peers_reply(['AGREED: yes', 'the plan'], ['AGREED: yes', 'LGTM: nothing to add'])

    collab.run('add a greeter')

    expect(session).to have_received(:run).once
  end

  it 'skips the review when nothing changed' do
    peers_reply(['AGREED: yes', 'the plan'], ['AGREED: yes'])

    collab.run('add a greeter')

    expect(screen.string).to include('nothing changed, so nothing to review')
  end

  it 'shows both agents in the transcript' do
    peers_reply(['AGREED: mine', 'the plan'], ['AGREED: yours', 'LGTM: fine'])

    collab.run('add a greeter')

    expect(screen.string).to include('A', 'claude-sonnet-5', 'B', 'gpt-5.4', 'AGREED: mine', 'AGREED: yours')
  end
end
