# frozen_string_literal: true

module RubyLLMCLI
  class ContextManager
    attr_reader :config
    
    def initialize(config)
      @config = config
    end
    
    # Check if user message is a new topic
    def check_new_topic(current_message, conversation_history = [])
      prompt = <<~PROMPT
        Determine if the user's message is starting a new topic compared to the conversation history.
        
        Consider it a new topic if:
        - The subject matter is significantly different
        - The user is asking about something unrelated to previous messages
        - The user explicitly indicates starting fresh (e.g., "new question", "different topic")
        
        Respond with only "true" or "false".
        
        Current message: #{current_message}
        
        Previous messages: #{conversation_history.last(3).join("\n")}
      PROMPT
      
      chat = RubyLLM.chat(
        model: "claude-3-haiku-20240307",
        messages: [{role: "user", content: prompt}]
      )
      response = chat.ask("Respond with only 'true' or 'false'")
      
      response.strip.downcase == "true"
    rescue
      false
    end
    
    # Compact conversation context
    def compact_context(messages)
      system_prompt = Prompts.compression_prompt
      
      # Build conversation history
      history = messages.map do |msg|
        "#{msg[:role]}: #{msg[:content]}"
      end.join("\n\n")
      
      # Add compaction instruction
      compact_prompt = <<~PROMPT
        <conversation_history>
        #{history}
        </conversation_history>
        
        Compress the above conversation into a state snapshot following the XML format described in your instructions.
        Focus on:
        - What the user wanted to accomplish
        - What was done so far
        - Key information discovered
        - Current state and next steps
      PROMPT
      
      chat = RubyLLM.chat(
        model: @config.model,
        messages: [
          {role: "system", content: system_prompt},
          {role: "user", content: compact_prompt}
        ]
      )
      response = ""
      chat.ask("Compress the conversation") do |chunk|
        response += chunk.content if chunk.content
      end
      response
      
      # Return compacted context as a system message
      {
        role: "system",
        content: "Previous conversation context:\n#{response}"
      }
    end
    
    # Summarize previous conversation for display
    def summarize_previous_conversation(messages)
      return nil if messages.empty?
      
      prompt = <<~PROMPT
        Summarize this conversation in 2-3 sentences, focusing on:
        - What the user was trying to accomplish
        - What was completed
        - Any important context
        
        Conversation:
        #{messages.map { |m| "#{m[:role]}: #{m[:content]}" }.join("\n\n")}
      PROMPT
      
      chat = RubyLLM.chat(
        model: "claude-3-haiku-20240307", 
        messages: [{role: "user", content: prompt}]
      )
      response = ""
      chat.ask("Provide summary") do |chunk|
        response += chunk.content if chunk.content
      end
      response.strip
    rescue
      nil
    end
    
    # Check quota (lightweight request)
    def check_quota
      chat = RubyLLM.chat(
        model: "claude-3-haiku-20240307",
        messages: [{role: "user", content: "quota"}]
      )
      chat.ask("Check quota")
      true
      true
    rescue => e
      puts "Warning: Quota check failed: #{e.message}"
      false
    end
  end
end