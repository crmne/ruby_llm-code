# frozen_string_literal: true

RSpec.describe RubyLLM::Code::Session do
  subject(:session) { described_class.new(config: config, ui: ui) }

  let(:config) { RubyLLM::Code::Config.new(model: 'claude-sonnet-5', workspace_dir: sandbox.root.to_s) }

  before do
    RubyLLM.configure do |setup|
      setup.anthropic_api_key = 'test'
      setup.openai_api_key = 'test'
    end
  end

  # Types +lines+ at the prompt, then end of input.
  def types(*lines)
    allow(ui).to receive(:ask_user).and_return(*lines, nil)
    allow(ui).to receive(:completions=)
  end

  # Lets a turn run without talking to a model.
  def silence_coder
    allow(session.coder).to receive(:ask_later)
    allow(session.coder).to receive(:complete)
    allow(session.coder).to receive(:awaiting_approval?).and_return(false)
  end

  it 'gives the coder every tool and the workspace instructions' do
    expect(session.coder.tools.keys).to eq(%i[read list glob grep write edit shell])
    expect(session.coder.messages.first.content).to include('RubyLLM Code', sandbox.root.to_s)
  end

  it 'asks the coder whatever is typed' do
    types('fix the parser')
    silence_coder

    session.repl

    expect(session.coder).to have_received(:ask_later).with('fix the parser')
  end

  it 'answers a slash command instead of asking the model' do
    types('/help')
    silence_coder

    session.repl

    expect(session.coder).not_to have_received(:ask_later)
    expect(screen.string).to include('/collab')
  end

  it 'leaves on /exit' do
    types('/exit', 'never asked')
    silence_coder

    session.repl

    expect(session.coder).not_to have_received(:ask_later)
  end

  it 'says so when a command does not exist' do
    types('/nope')

    session.repl

    expect(screen.string).to include('no such command: /nope')
  end

  it 'pairs up and breaks up' do
    types('/collab gpt-5.4 3', '/collab off')

    session.repl

    expect(screen.string).to include('collab · claude-sonnet-5 + gpt-5.4 · 3 rounds', 'collab · off')
  end

  it 'sends a collaborative turn to the pair' do
    session.pair_with('gpt-5.4')
    allow(session.collab).to receive(:run)

    session.ask('add a greeter')

    expect(session.collab).to have_received(:run).with('add a greeter')
  end

  it 'switches models' do
    types('/model claude-opus-4-6')

    session.repl

    expect(session.coder.model.id).to eq('claude-opus-4-6')
  end

  it 'complains about a model nobody has heard of' do
    types('/model gpt-9000')

    session.repl

    expect(screen.string).to include('gpt-9000')
  end

  it 'forgets the conversation on /clear' do
    session.coder.ask_later('remember this')
    types('/clear')

    session.repl

    expect(session.coder.messages.map(&:role)).to eq([:system])
  end

  it 'stops asking once yolo is on' do
    types('/yolo')

    session.repl

    expect(config.yolo).to be(true)
  end

  describe 'approvals' do
    let(:call) { RubyLLM::ToolCall.new(id: '1', name: 'write', arguments: { 'path' => 'a.rb', 'content' => 'x' }) }

    # A turn where the loop parks once, waiting on one tool call.
    before do
      allow(session.coder).to receive(:ask_later)
      allow(session.coder).to receive(:complete)
      allow(session.coder).to receive(:awaiting_approval?).and_return(true, false)
      allow(session.coder).to receive(:pending_approvals).and_return([call])
      allow(session.coder).to receive(:approve!)
      allow(session.coder).to receive(:deny!)
    end

    it 'runs the tool when the developer says yes' do
      allow(ui).to receive(:approval).and_return(:yes)

      session.run('write it')

      expect(session.coder).to have_received(:approve!).with(call)
    end

    it 'refuses the tool when the developer says no' do
      allow(ui).to receive(:approval).and_return(:no)

      session.run('write it')

      expect(session.coder).to have_received(:deny!).with(call)
    end

    it 'stops asking after always' do
      allow(ui).to receive(:approval).and_return(:always)

      session.run('write it')

      expect(config.yolo).to be(true)
      expect(session.coder).to have_received(:approve!).with(call)
    end

    it 'never asks in yolo mode' do
      config.yolo = true
      allow(ui).to receive(:approval)

      session.run('write it')

      expect(ui).not_to have_received(:approval)
      expect(session.coder).to have_received(:approve!).with(call)
    end
  end

  it 'accounts for the collaborators too' do
    session.pair_with('gpt-5.4')

    expect(session.chats.keys).to eq(%w[coder A B])
  end

  it 'reports nothing spent yet without falling over' do
    types('/cost')

    session.repl

    expect(screen.string).to include('claude-sonnet-5', '$0.0000')
  end

  it 'lists its tools and what they may do' do
    types('/tools')

    session.repl

    expect(screen.string).to include('shell', 'asks first', 'read', 'runs')
  end
end
