# frozen_string_literal: true

RSpec.describe RubyLLM::Code::Config do
  it 'picks a model the exported key can reach' do
    with_env('ANTHROPIC_API_KEY' => 'test', 'OPENAI_API_KEY' => nil) do
      expect(config.model).to eq('claude-sonnet-5')
    end

    with_env('ANTHROPIC_API_KEY' => nil, 'OPENAI_API_KEY' => 'test') do
      expect(config.model).to eq('gpt-5.4')
    end
  end

  it 'lets the command line win' do
    with_env('RUBYLLM_MODEL' => 'gemini-3.1-pro-preview') do
      expect(config(model: 'claude-opus-4-6').model).to eq('claude-opus-4-6')
      expect(config.model).to eq('gemini-3.1-pro-preview')
    end
  end

  it 'hands the keys it finds to RubyLLM' do
    with_env('ANTHROPIC_API_KEY' => 'sk-test', 'GEMINI_API_KEY' => 'gm-test') do
      config.apply!

      expect(RubyLLM.config.anthropic_api_key).to eq('sk-test')
      expect(RubyLLM.config.gemini_api_key).to eq('gm-test')
    end
  end

  private

  def config(**overrides)
    described_class.new(workspace_dir: sandbox.root.to_s, **overrides)
  end

  def with_env(values)
    was = values.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    was.each { |key, value| ENV[key] = value }
  end
end
