# frozen_string_literal: true

require 'ruby_llm'
require 'zeitwerk'

require_relative 'code/version'

module RubyLLM
  # A minimal coding agent for the terminal, built on RubyLLM.
  #
  # A Session owns one Coder agent and the REPL around it. Ask it to change
  # something and it reads, writes, and runs code in a Workspace. Turn on
  # collaboration with Collab and a second model joins: the two explore the
  # workspace at the same time, argue about the approach, and only then does
  # the coder touch your files.
  module Code
    # Raised for anything this gem refuses or cannot do.
    class Error < StandardError; end

    # Raised inside tools for conditions the model should see and correct.
    class ToolError < Error; end

    class << self
      def loader
        @loader ||= Zeitwerk::Loader.new.tap do |loader|
          loader.tag = 'ruby_llm-code'
          loader.inflector.inflect('cli' => 'CLI', 'ui' => 'UI')
          loader.push_dir("#{__dir__}/code", namespace: RubyLLM::Code)
          loader.ignore("#{__dir__}/code/version.rb")
        end
      end
    end
  end
end

RubyLLM::Code.loader.setup

# The agents' words live in ERB files rendered through RubyLLM's prompt
# templates. An application's own app/prompts is searched first, so any project
# can override a prompt shipped here by writing a file with the same name.
RubyLLM::Prompt.roots << "#{__dir__}/code/prompts"
