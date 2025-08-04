# frozen_string_literal: true

require "ruby_llm"
require "fileutils"
require "yaml"
require "json"
require "readline"
require "io/console"
require "optparse"
require "pathname"
require "tempfile"
require "open3"
require "digest"
require "net/http"
require "uri"
require "logger"

module RubyLLMCLI
  class Error < StandardError; end
end

# Load all files in proper order
require_relative "rubyllm_cli/version"
require_relative "rubyllm_cli/colors"
require_relative "rubyllm_cli/prompts"
require_relative "rubyllm_cli/workspace"
require_relative "rubyllm_cli/configuration"
require_relative "rubyllm_cli/config"
require_relative "rubyllm_cli/ruby_llm_configurator"
require_relative "rubyllm_cli/memory"
require_relative "rubyllm_cli/mcp_manager"
require_relative "rubyllm_cli/context_manager"
require_relative "rubyllm_cli/output_formatter"
require_relative "rubyllm_cli/tool_wrapper"
require_relative "rubyllm_cli/syntax_highlighter"

# Tools
require_relative "rubyllm_cli/tools/base_tool"
require_relative "rubyllm_cli/tools/read_file"
require_relative "rubyllm_cli/tools/write_file"
require_relative "rubyllm_cli/tools/edit_file"
require_relative "rubyllm_cli/tools/multi_edit"
require_relative "rubyllm_cli/tools/list_directory"
require_relative "rubyllm_cli/tools/glob"
require_relative "rubyllm_cli/tools/grep"
require_relative "rubyllm_cli/tools/shell"
require_relative "rubyllm_cli/tools/web_search"
require_relative "rubyllm_cli/tools/web_fetch"
require_relative "rubyllm_cli/tools/memory_tool"
require_relative "rubyllm_cli/tools/todo_write"
require_relative "rubyllm_cli/tools/task"
require_relative "rubyllm_cli/tools/exit_plan_mode"

# Command handling
require_relative "rubyllm_cli/memory_commands"
require_relative "rubyllm_cli/mcp_commands"
require_relative "rubyllm_cli/command_processor"
require_relative "rubyllm_cli/conversation_manager"
require_relative "rubyllm_cli/message_handler"

# CLI
require_relative "rubyllm_cli/non_interactive_cli"
require_relative "rubyllm_cli/interactive_cli"
require_relative "rubyllm_cli/cli"