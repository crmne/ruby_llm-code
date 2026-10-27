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

  context 'with symlinks' do
    # A folder outside the workspace, and a link to it from inside.
    let(:outside) { Pathname.new(Dir.mktmpdir('outside')) }

    before do
      outside.join('secret.txt').write("outside\n")
      sandbox.root.join('link').make_symlink(outside)
    end

    after { FileUtils.remove_entry(outside) }

    it 'refuses a file that a link inside leads to outside' do
      expect { sandbox.resolve('link/secret.txt') }.to raise_error(RubyLLM::Code::ToolError, /outside the workspace/)
    end

    it 'refuses a new file in a folder that a link leads to outside' do
      expect { sandbox.resolve('link/planted.txt') }.to raise_error(RubyLLM::Code::ToolError, /outside the workspace/)
    end

    it 'refuses the link itself' do
      expect { sandbox.resolve('link') }.to raise_error(RubyLLM::Code::ToolError, /outside the workspace/)
    end

    it 'refuses a broken link, which writing would follow wherever it points' do
      sandbox.root.join('dangling').make_symlink(outside.join('not-yet.txt'))

      expect { sandbox.resolve('dangling') }.to raise_error(RubyLLM::Code::ToolError, /broken symlink/)
      expect { sandbox.resolve('dangling/inside.txt') }.to raise_error(RubyLLM::Code::ToolError, /broken symlink/)
    end

    it 'follows links that stay inside' do
      file('lib/thing.rb')
      sandbox.root.join('code').make_symlink(sandbox.root.join('lib'))

      expect(sandbox.resolve('code/thing.rb').to_s).to eq(sandbox.root.join('code/thing.rb').to_s)
    end

    it 'leaves links that lead outside out of globs' do
      file('lib/thing.rb')

      expect(sandbox.files('**/*').map { |path| sandbox.relative(path) }).to eq(['lib/thing.rb'])
    end

    it 'still resolves new files in folders that do not exist yet' do
      expect(sandbox.resolve('new/deep/file.rb').to_s).to eq(sandbox.root.join('new/deep/file.rb').to_s)
    end

    it 'works from a root reached through a link, as temporary folders are on macOS' do
      sandbox.root.join('real').mkpath
      sandbox.root.join('real/inner.txt').write("x\n")
      sandbox.root.join('via').make_symlink(sandbox.root.join('real'))
      linked = described_class.new(sandbox.root.join('via').to_s)

      expect(linked.resolve('inner.txt').to_s).to eq(sandbox.root.join('via/inner.txt').to_s)
      expect { linked.resolve('../link/secret.txt') }.to raise_error(RubyLLM::Code::ToolError)
    end
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
