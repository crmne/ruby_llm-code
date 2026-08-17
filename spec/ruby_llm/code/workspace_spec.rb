# frozen_string_literal: true

RSpec.describe RubyLLM::Code::Workspace do
  it 'resolves paths inside itself' do
    expect(sandbox.resolve('lib/thing.rb').to_s).to eq(sandbox.root.join('lib/thing.rb').to_s)
  end

  it 'refuses paths that climb out' do
    expect { sandbox.resolve('../../etc/passwd') }.to raise_error(RubyLLM::Code::ToolError, /outside the workspace/)
  end

  it 'refuses absolute paths elsewhere' do
    expect { sandbox.resolve('/etc/passwd') }.to raise_error(RubyLLM::Code::ToolError)
  end

  it 'refuses an empty path' do
    expect { sandbox.resolve('  ') }.to raise_error(RubyLLM::Code::ToolError, /required/)
  end

  it 'knows what is noise' do
    expect(sandbox.noise?(sandbox.root.join('node_modules/left-pad/index.js'))).to be(true)
    expect(sandbox.noise?(sandbox.root.join('lib/left_pad.rb'))).to be(false)
  end

  it 'lists the top level, skipping noise' do
    file('lib/thing.rb')
    file('node_modules/junk/index.js')

    expect(sandbox.overview).to eq('lib/')
  end

  it 'reads the project instructions when there are any' do
    file('AGENTS.md', "Use tabs, obviously.\n")

    expect(sandbox.context).to include('AGENTS.md', 'Use tabs')
  end

  it 'has no context when the project left none' do
    expect(sandbox.context).to be_empty
  end

  it 'refuses to open somewhere that is not a directory' do
    expect { described_class.new(file('lib/thing.rb').to_s) }.to raise_error(RubyLLM::Code::Error, /not a directory/)
  end
end
