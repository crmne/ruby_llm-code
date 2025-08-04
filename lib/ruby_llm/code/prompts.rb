# frozen_string_literal: true

module RubyLLM::Code
  class Prompts
    PROMPTS_DIR = File.expand_path("prompts", __dir__)
    
    def self.system_prompt(config)
      # Use minimal prompt for Gemini models
      if config.model.to_s.downcase.include?("gemini")
        prompt = "You are a helpful assistant for software developers. You help with coding tasks, answer technical questions, and provide creative solutions when asked."
        
        # Add memory section if available
        memory_section = config.memory&.to_prompt
        if memory_section
          prompt + "\n\n" + memory_section
        else
          prompt
        end
      else
        # Load full system prompts for other models
        identity = load_prompt("system-identity.md")
        workflow = load_prompt("system-workflow.md")
        
        # Replace placeholders in workflow
        workflow = workflow
          .gsub("$cwd", config.workspace.root)
          .gsub("$boolean", config.workspace.git? ? "Yes" : "No")
          .gsub("$OS", RUBY_PLATFORM.include?("darwin") ? "macOS" : "Linux")
          .gsub("$OS_version", `uname -a`.strip)
          .gsub("$date", Date.today.strftime("%Y-%m-%d"))
          .gsub("$gitStatus", git_status_info)
        
        # Combine prompts
        combined = [identity, workflow].join("\n\n")
        
        # Add memory section if available
        memory_section = config.memory&.to_prompt
        if memory_section
          combined + "\n\n" + memory_section
        else
          combined
        end
      end
    end
    
    def self.system_reminder_start
      load_prompt("system-reminder-start.md")
    end
    
    def self.system_reminder_end(todos = nil)
      if todos.nil? || todos.empty?
        load_prompt("system-reminder-end.md")
      else
        # Format todos for display
        todo_list = todos.map { |t| "- [#{t["status"]}] #{t["content"]}" }.join("\n")
        "<system-reminder>Your current todo list:\n#{todo_list}\n\nContinue working on your tasks.</system-reminder>"
      end
    end
    
    
    private
    
    def self.load_prompt(filename)
      path = File.join(PROMPTS_DIR, filename)
      File.read(path)
    end
    
    def self.git_status_info
      return "" unless Dir.exist?(".git")
      
      status = `git status --porcelain 2>/dev/null`
      branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
      
      <<~STATUS
        Current branch: #{branch}
        
        Status:
        #{status.empty? ? "Working tree clean" : status}
        
        Recent commits:
        #{`git log --oneline -5 2>/dev/null`}
      STATUS
    rescue
      ""
    end
    
    def self.compression_prompt
      <<~PROMPT
        You are the component that summarizes internal chat history into a structured format.
        
        When the conversation history grows too large, you will distill it into a concise XML snapshot.
        This snapshot is CRITICAL as it becomes the agent's only memory of the past.
        
        First, think through the entire history in a <scratchpad>. Review:
        - User's overall goal
        - Agent's actions and tool outputs
        - File modifications
        - Unresolved questions
        
        Then generate the final <state_snapshot> XML:
        
        <state_snapshot>
          <overall_goal>
            <!-- Single sentence describing user's objective -->
          </overall_goal>
          
          <key_knowledge>
            <!-- Crucial facts and conventions (bullet points) -->
          </key_knowledge>
          
          <file_system_state>
            <!-- Files created/modified/deleted with status -->
          </file_system_state>
          
          <recent_actions>
            <!-- Summary of last significant actions -->
          </recent_actions>
          
          <current_plan>
            <!-- Step-by-step plan with status markers -->
          </current_plan>
        </state_snapshot>
      PROMPT
    end
  end
end