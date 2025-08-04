# frozen_string_literal: true

module RubyLLMCLI
  module Tools
    class Task < BaseTool
      def name
        "Task"
      end

      description <<~DESC
          Launch a new agent to handle complex, multi-step tasks autonomously.

          Available agent types and the tools they have access to:
          - general-purpose: General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you. (Tools: *)

          When using the Task tool, you must specify a subagent_type parameter to select which agent type to use.

          When to use the Agent tool:
          - When you are instructed to execute custom slash commands. Use the Agent tool with the slash command invocation as the entire prompt. The slash command can take arguments. For example: Task(description="Check the file", prompt="/check-file path/to/file.py")

          When NOT to use the Agent tool:
          - If you want to read a specific file path, use the Read or Glob tool instead of the Agent tool, to find the match more quickly
          - If you are searching for a specific class definition like "class Foo", use the Glob tool instead, to find the match more quickly
          - If you are searching for code within a specific file or set of 2-3 files, use the Read tool instead of the Agent tool, to find the match more quickly
          - Other tasks that are not related to the agent descriptions above

          Usage notes:
          1. Launch multiple agents concurrently whenever possible, to maximize performance; to do that, use a single message with multiple tool uses
          2. When the agent is done, it will return a single message back to you. The result returned by the agent is not visible to the user. To show the user the result, you should send a text message back to the user with a concise summary of the result.
          3. Each agent invocation is stateless. You will not be able to send additional messages to the agent, nor will the agent be able to communicate with you outside of its final report. Therefore, your prompt should contain a highly detailed task description for the agent to perform autonomously and you should specify exactly what information the agent should return back to you in its final and only message to you.
          4. The agent's outputs should generally be trusted
          5. Clearly tell the agent whether you expect it to write code or just to do research (search, file reads, web fetches, etc.), since it is not aware of the user's intent
          6. If the agent description mentions that it should be used proactively, then you should try your best to use it without the user having to ask for it first. Use your judgement.
        DESC
      
      param :description, desc: "A short (3-5 word) description of the task"
      param :prompt, desc: "The task for the agent to perform"
      param :subagent_type, desc: "The type of specialized agent to use for this task"
      
      def execute(description:, prompt:, subagent_type:)
        # Create a new sub-agent context
        sub_config = config.dup
        
        # Build sub-agent system prompt
        sub_system_prompt = <<~PROMPT
          You are a sub-agent working on a specific task. Your role is to complete the task autonomously and return a comprehensive report.
          
          Task Type: #{subagent_type}
          Task Description: #{description}
          
          Remember:
          - You cannot interact with the user or the main agent after this message
          - Provide a complete, self-contained report of your findings
          - Be thorough but concise in your final response
        PROMPT
        
        # Create sub-chat with the task prompt
        sub_chat = RubyLLM.chat(
          model: config.model,
          messages: [
            { role: "system", content: sub_system_prompt },
            { role: "user", content: prompt }
          ],
          tools: available_tools
        )
        
        # Execute the sub-agent task
        result = ""
        sub_chat.stream do |chunk|
          result += chunk if chunk.is_a?(String)
        end
        
        # Return the sub-agent's final report
        <<~RESULT
          Sub-agent (#{subagent_type}) completed task: #{description}
          
          Report:
          #{result}
        RESULT
      rescue => e
        "Sub-agent failed with error: #{e.message}"
      end
      
      private
      
      def available_tools
        # Return all available tools for sub-agent
        Dir[File.join(__dir__, "*.rb")].map do |file|
          tool_name = File.basename(file, ".rb")
          next if tool_name == "base_tool" || tool_name == "task"
          
          tool_class = RubyLLMCLI::Tools.const_get(tool_name.split("_").map(&:capitalize).join)
          tool_class.new(config)
        end.compact
      end
    end
  end
end