# frozen_string_literal: true

module RubyLLM::Code
  module RubyLLMConfigurator
    def self.configure
      RubyLLM.configure do |config|
        config.openai_api_key = ENV.fetch('OPENAI_API_KEY', nil)
        config.anthropic_api_key = ENV.fetch('ANTHROPIC_API_KEY', nil)
        config.gemini_api_key = ENV.fetch('GEMINI_API_KEY', nil)
        config.deepseek_api_key = ENV.fetch('DEEPSEEK_API_KEY', nil)
        config.perplexity_api_key = ENV.fetch('PERPLEXITY_API_KEY', nil)
        config.openrouter_api_key = ENV.fetch('OPENROUTER_API_KEY', nil)
        config.mistral_api_key = ENV.fetch('MISTRAL_API_KEY', nil)
        config.ollama_api_base = ENV.fetch('OLLAMA_API_BASE', nil)

        config.gpustack_api_base = ENV.fetch('GPUSTACK_API_BASE', nil)
        config.gpustack_api_key = ENV.fetch('GPUSTACK_API_KEY', nil)

        config.bedrock_api_key = ENV.fetch('AWS_ACCESS_KEY_ID', nil)
        config.bedrock_secret_key = ENV.fetch('AWS_SECRET_ACCESS_KEY', nil)
        config.bedrock_region = 'us-west-2'
        config.bedrock_session_token = ENV.fetch('AWS_SESSION_TOKEN', nil)

        # Simple logging configuration (from conversation_manager.rb)
        if ENV["DEBUG"]
          log_dir = File.join(Configuration::CONFIG_DIR, "logs")
          FileUtils.mkdir_p(log_dir)
          
          log_file = File.join(log_dir, "rubyllm_debug.log")
          config.log_file = log_file
          config.log_level = Logger::DEBUG
        end
      end
    end
  end
end