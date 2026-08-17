# frozen_string_literal: true

RSpec.describe RubyLLM::Code::UI::Markdown do
  subject(:stream) { ui.markdown_stream }

  it 'holds a paragraph until it is finished' do
    stream << 'a sentence that is not'

    expect(screen.string).to be_empty

    stream << " done yet\n\n"

    expect(screen.string).to include('a sentence that is not done yet')
  end

  it 'holds a code block until the fence closes' do
    stream << "```ruby\nputs 1\n"

    expect(screen.string).to be_empty

    stream << "```\n"

    expect(screen.string).to include('puts 1')
  end

  it 'does not break a code block on the blank lines inside it' do
    stream << "```ruby\nputs 1\n\nputs 2\n```\n"

    expect(screen.string).to include('puts 1', 'puts 2')
  end

  it 'prints what is left when the answer ends' do
    stream << 'no trailing newline'
    stream.close

    expect(screen.string).to include('no trailing newline')
  end

  it 'stays quiet when there is nothing to say' do
    stream << "   \n\n"
    stream.close

    expect(screen.string).to be_empty
  end
end
