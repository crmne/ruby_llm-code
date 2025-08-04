# frozen_string_literal: true

require "json"
require "fileutils"

module RubyLLMCLI
  module Tools
    class TodoWrite < BaseTool
      def name
        "TodoWrite"
      end
      description <<~DESC
          Use this tool to create and manage a structured task list for your current coding session. This helps you track progress, organize complex tasks, and demonstrate thoroughness to the user.
          It also helps the user understand the progress of the task and overall progress of their requests.

          ## When to Use This Tool
          Use this tool proactively in these scenarios:

          1. Complex multi-step tasks - When a task requires 3 or more distinct steps or actions
          2. Non-trivial and complex tasks - Tasks that require careful planning or multiple operations
          3. User explicitly requests todo list - When the user directly asks you to use the todo list
          4. User provides multiple tasks - When users provide a list of things to be done (numbered or comma-separated)
          5. After receiving new instructions - Immediately capture user requirements as todos
          6. When you start working on a task - Mark it as in_progress BEFORE beginning work. Ideally you should only have one todo as in_progress at a time
          7. After completing a task - Mark it as completed and add any new follow-up tasks discovered during implementation

          ## When NOT to Use This Tool

          Skip using this tool when:
          1. There is only a single, straightforward task
          2. The task is trivial and tracking it provides no organizational benefit
          3. The task can be completed in less than 3 trivial steps
          4. The task is purely conversational or informational

          NOTE that you should not use this tool if there is only one trivial task to do. In this case you are better off just doing the task directly.
        DESC
      
      param :todos, type: "array", desc: "The updated todo list", required: true
      
      def execute(todos:)
        # Ensure todos directory exists
        todos_dir = File.expand_path("~/.rubyllm/todos")
        FileUtils.mkdir_p(todos_dir)
        
        # Create a unique filename based on process ID and timestamp
        filename = "todos_#{Process.pid}_#{Time.now.to_i}.json"
        filepath = File.join(todos_dir, filename)
        
        # Write todos to file
        File.write(filepath, JSON.pretty_generate(todos))
        
        # Also maintain a "current" symlink for easy access
        current_link = File.join(todos_dir, "current.json")
        FileUtils.rm_f(current_link) if File.exist?(current_link)
        FileUtils.ln_s(filepath, current_link)
        
        # Return formatted todo list
        formatted_todos = todos.map do |todo|
          status_icon = case todo["status"]
                       when "completed" then "✓"
                       when "in_progress" then "→"
                       else "○"
                       end
          "#{status_icon} [#{todo["priority"]}] #{todo["content"]}"
        end.join("\n")
        
        "Todos have been modified successfully. Ensure that you continue to use the todo list to track your progress. Please proceed with the current tasks if applicable"
      end
      
      def self.load_current_todos
        current_file = File.expand_path("~/.rubyllm/todos/current.json")
        return nil unless File.exist?(current_file)
        
        JSON.parse(File.read(current_file))
      rescue JSON::ParserError
        nil
      end
    end
  end
end