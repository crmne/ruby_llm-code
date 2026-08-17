# frozen_string_literal: true

RSpec.describe RubyLLM::Code::Tools do
  it 'names its tools the way the model calls them' do
    expect(tools.keys).to eq(%w[read list glob grep write edit shell])
  end

  it 'only hands out the harmless ones for collaboration' do
    expect(described_class.read_only(sandbox).map(&:name)).to eq(%w[read list glob grep])
  end

  it 'asks before it changes anything' do
    asking, running = tools.values.partition(&:requires_approval?)

    expect(asking.map(&:name)).to eq(%w[write edit shell])
    expect(running.map(&:name)).to eq(%w[read list glob grep])
  end

  it 'labels a call the way it reads in the transcript' do
    expect(described_class.label(call('read', 'path' => 'lib/thing.rb'))).to eq('read(lib/thing.rb)')
    expect(described_class.label(call('shell', command: 'rake'))).to eq('shell(rake)')
  end

  it 'previews only what would change something' do
    expect(described_class.preview(call('read', 'path' => 'lib/thing.rb'))).to be_nil
    expect(described_class.preview(call('edit', old_string: 'a', new_string: 'b'))).to eq("```diff\n-a\n+b\n```")
  end

  describe 'read' do
    it 'returns the file with line numbers' do
      file('lib/thing.rb', "one\ntwo\n")

      expect(tools['read'].execute(path: 'lib/thing.rb')).to eq("lib/thing.rb (2 lines)\n     1\tone\n     2\ttwo")
    end

    it 'reads a window of a longer file' do
      file('lib/thing.rb', (1..10).map { |n| "line #{n}\n" }.join)

      result = tools['read'].execute(path: 'lib/thing.rb', offset: 3, limit: 2)

      expect(result).to include('lines 3-4 of 10', 'line 3', 'line 4')
      expect(result).not_to include('line 5')
    end

    it 'says so when the file is not there' do
      expect(tools['read'].execute(path: 'nope.rb')).to eq(error: 'nope.rb does not exist')
    end

    it 'refuses binary files' do
      file('thing.png', "\x89PNG\x00\x01")

      expect(tools['read'].execute(path: 'thing.png')).to eq(error: 'thing.png looks binary')
    end
  end

  describe 'list' do
    it 'marks directories and skips noise' do
      file('lib/thing.rb')
      file('node_modules/junk/index.js')

      expect(tools['list'].execute).to include('lib/')
      expect(tools['list'].execute).not_to include('node_modules')
    end
  end

  describe 'glob' do
    it 'finds files by pattern, newest first' do
      old = file('lib/old.rb')
      file('lib/new.rb')
      File.utime(Time.now - 60, Time.now - 60, old)

      expect(tools['glob'].execute(pattern: 'lib/*.rb')).to eq("lib/new.rb\nlib/old.rb")
    end

    it 'says so when nothing matches' do
      expect(tools['glob'].execute(pattern: '*.exe')).to eq('No files match *.exe')
    end

    it 'cannot list a sibling file outside the sandbox' do
      outside = sandbox.root.dirname.join("outside-#{sandbox.root.basename}.rb")
      outside.write('secret')

      expect(tools['glob'].execute(pattern: '../*')).not_to include(outside.basename.to_s)
    ensure
      outside&.delete
    end
  end

  describe 'grep' do
    it 'returns matches with file and line' do
      file('lib/thing.rb', "def hello\n  :hi\nend\n")

      expect(tools['grep'].execute(pattern: 'def hello')).to eq('lib/thing.rb:1:def hello')
    end

    it 'searches without ripgrep too' do
      file('lib/thing.rb', "def hello\nend\n")

      matches = tools['grep'].send(:search, 'def hello', sandbox.root, nil, false)

      expect(matches).to eq(['lib/thing.rb:1:def hello'])
    end

    it 'says so when nothing matches' do
      file('lib/thing.rb')

      expect(tools['grep'].execute(pattern: 'nowhere')).to eq('No matches for nowhere')
    end

    it 'cannot read content from a file outside the sandbox' do
      outside = sandbox.root.dirname.join("outside-#{sandbox.root.basename}.rb")
      outside.write("top secret\n")

      expect(tools['grep'].execute(pattern: 'top secret', glob: '../*')).to eq('No matches for top secret')
    ensure
      outside&.delete
    end
  end

  describe 'write' do
    it 'creates the file and any directories above it' do
      expect(tools['write'].execute(path: 'lib/deep/thing.rb', content: "puts 1\n")).to include('Created')
      expect(sandbox.root.join('lib/deep/thing.rb').read).to eq("puts 1\n")
    end

    it 'previews what it would write' do
      preview = RubyLLM::Code::Tools::Write.preview(path: 'a.rb', content: "puts 1\n")

      expect(preview).to eq("```rb\nputs 1\n```")
    end
  end

  describe 'edit' do
    it 'replaces an exact string' do
      file('lib/thing.rb', "puts 1\n")

      tools['edit'].execute(path: 'lib/thing.rb', old_string: 'puts 1', new_string: 'puts 2')

      expect(sandbox.root.join('lib/thing.rb').read).to eq("puts 2\n")
    end

    it 'refuses an ambiguous match' do
      file('lib/thing.rb', "puts 1\nputs 1\n")

      expect(tools['edit'].execute(path: 'lib/thing.rb', old_string: 'puts 1', new_string: 'puts 2'))
        .to eq(error: 'old_string appears 2 times in lib/thing.rb: add context or pass replace_all')
    end

    it 'replaces every occurrence when told to' do
      file('lib/thing.rb', "puts 1\nputs 1\n")

      tools['edit'].execute(path: 'lib/thing.rb', old_string: 'puts 1', new_string: 'puts 2', replace_all: true)

      expect(sandbox.root.join('lib/thing.rb').read).to eq("puts 2\nputs 2\n")
    end

    it 'says so when the old string is not there' do
      file('lib/thing.rb', "puts 1\n")

      expect(tools['edit'].execute(path: 'lib/thing.rb', old_string: 'nope', new_string: 'x'))
        .to eq(error: 'old_string not found in lib/thing.rb')
    end

    it 'writes new_string literally, not as a regexp backreference' do
      file('lib/thing.rb', "puts 1\n")
      new_string = ['a', "\u005c", '1b'].join

      tools['edit'].execute(path: 'lib/thing.rb', old_string: 'puts 1', new_string: new_string)

      expect(sandbox.root.join('lib/thing.rb').read).to eq("#{new_string}\n")
    end

    it 'writes new_string literally on every occurrence with replace_all' do
      file('lib/thing.rb', "puts 1\nputs 1\n")
      new_string = ['a', "\u005c", '1b'].join

      tools['edit'].execute(path: 'lib/thing.rb', old_string: 'puts 1', new_string: new_string, replace_all: true)

      expect(sandbox.root.join('lib/thing.rb').read).to eq("#{new_string}\n#{new_string}\n")
    end
  end

  describe 'shell' do
    it 'runs a command from the workspace root' do
      file('lib/thing.rb')

      expect(tools['shell'].execute(command: 'ls lib')).to eq('thing.rb')
    end

    it 'reports a failing exit status' do
      expect(tools['shell'].execute(command: 'exit 3')).to start_with('exit status 3')
    end

    it 'gives up on a command that hangs' do
      expect(tools['shell'].call({ command: 'sleep 5', timeout: 1 })).to eq(error: 'timed out after 1s: sleep 5')
    end
  end

  it 'turns a refusal into something the model can read' do
    expect(tools['read'].call({ path: '../outside.rb' })).to match(error: /outside the workspace/)
  end

  private

  def call(name, arguments)
    RubyLLM::ToolCall.new(id: '1', name: name, arguments: arguments)
  end
end
