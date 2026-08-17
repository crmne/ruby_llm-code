# frozen_string_literal: true

module RubyLLM
  module Code
    # What the agent needs to know before it boots: which model answers, which
    # model it collaborates with, and where the credentials are.
    #
    # Nothing here is required. With one provider key exported, the defaults
    # pick a model that key can actually reach.
    class Config
      # First choice of model per provider, by the key that unlocks it.
      DEFAULT_MODELS = {
        'ANTHROPIC_API_KEY' => 'claude-sonnet-5',
        'OPENAI_API_KEY' => 'gpt-5.4',
        'GEMINI_API_KEY' => 'gemini-3.1-pro-preview',
        'OPENROUTER_API_KEY' => 'openai/gpt-5.4'
      }.freeze

      # Credentials whose environment variable is not just the RubyLLM setting
      # shouted.
      ENV_ALIASES = {
        vertexai_project_id: 'GOOGLE_CLOUD_PROJECT',
        vertexai_location: 'GOOGLE_CLOUD_LOCATION',
        bedrock_region: 'AWS_REGION'
      }.freeze

      DEFAULT_ROUNDS = 2

      attr_accessor :model, :partner_model, :rounds, :yolo, :workspace_dir

      def initialize(model: nil, partner_model: nil, rounds: nil, yolo: false, workspace_dir: nil)
        @workspace_dir = workspace_dir || Dir.pwd
        @model = model || ENV['RUBYLLM_MODEL'] || default_model
        @partner_model = partner_model || ENV.fetch('RUBYLLM_PARTNER_MODEL', nil)
        @rounds = (rounds || DEFAULT_ROUNDS).to_i
        @yolo = yolo
      end

      # Hands every credential in the environment to RubyLLM, so all seventeen
      # providers are reachable without naming them one by one.
      def apply!
        RubyLLM.configure do |config|
          credentials.each { |setting, value| config.public_send(:"#{setting}=", value) }
        end
        self
      end

      private

      def credentials
        provider_settings.filter_map do |setting|
          value = ENV[setting.to_s.upcase] || ENV.fetch(ENV_ALIASES[setting].to_s, nil)
          [setting, value] unless value.to_s.empty?
        end
      end

      def provider_settings
        @provider_settings ||= RubyLLM::Provider.providers.each_value.flat_map(&:configuration_requirements).uniq
      end

      def default_model
        key = DEFAULT_MODELS.keys.find { |name| !ENV[name].to_s.empty? }
        key ? DEFAULT_MODELS[key] : RubyLLM.config.default_model
      end
    end
  end
end
