# frozen_string_literal: true

# RubyLLM Code v0.1.0 - Placeholder release
# Full implementation coming soon!

require 'ruby_llm'
require 'fileutils'
require 'yaml'
require 'json'
require 'readline'
require 'io/console'
require 'optparse'
require 'pathname'
require 'tempfile'
require 'open3'
require 'digest'
require 'net/http'
require 'uri'
require 'logger'

module RubyLLM
  module Code
    class Error < StandardError; end
  end
end

# Load all files in proper order
require_relative 'ruby_llm/code/version'
require_relative 'ruby_llm/code/colors'
require_relative 'ruby_llm/code/prompts'
require_relative 'ruby_llm/code/workspace'
require_relative 'ruby_llm/code/configuration'
require_relative 'ruby_llm/code/config'
require_relative 'ruby_llm/code/ruby_llm_configurator'
require_relative 'ruby_llm/code/memory'
require_relative 'ruby_llm/code/mcp_manager'
require_relative 'ruby_llm/code/context_manager'
require_relative 'ruby_llm/code/output_formatter'
require_relative 'ruby_llm/code/tool_wrapper'
require_relative 'ruby_llm/code/syntax_highlighter'

# Tools
require_relative 'ruby_llm/code/tools/base_tool'
require_relative 'ruby_llm/code/tools/read_file'
require_relative 'ruby_llm/code/tools/write_file'
require_relative 'ruby_llm/code/tools/edit_file'
require_relative 'ruby_llm/code/tools/multi_edit'
require_relative 'ruby_llm/code/tools/list_directory'
require_relative 'ruby_llm/code/tools/glob'
require_relative 'ruby_llm/code/tools/grep'
require_relative 'ruby_llm/code/tools/shell'
require_relative 'ruby_llm/code/tools/web_search'
require_relative 'ruby_llm/code/tools/web_fetch'
require_relative 'ruby_llm/code/tools/memory_tool'
require_relative 'ruby_llm/code/tools/todo_write'
require_relative 'ruby_llm/code/tools/task'
require_relative 'ruby_llm/code/tools/exit_plan_mode'

# Command handling
require_relative 'ruby_llm/code/memory_commands'
require_relative 'ruby_llm/code/mcp_commands'
require_relative 'ruby_llm/code/command_processor'
require_relative 'ruby_llm/code/conversation_manager'
require_relative 'ruby_llm/code/message_handler'

# CLI
require_relative 'ruby_llm/code/non_interactive_cli'
require_relative 'ruby_llm/code/interactive_cli'
require_relative 'ruby_llm/code/cli'
