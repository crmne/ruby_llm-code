# frozen_string_literal: true

require 'ruby_llm/code'
require 'tmpdir'
require 'fileutils'
require 'stringio'

# A throwaway workspace, plus a UI that writes somewhere we can read back.
module Sandbox
  def sandbox
    @sandbox ||= RubyLLM::Code::Workspace.new(Dir.mktmpdir('ruby_llm-code'))
  end

  def file(path, content = "puts 1\n")
    full = sandbox.root.join(path)
    FileUtils.mkdir_p(full.dirname)
    full.write(content)
    full
  end

  def tools
    @tools ||= RubyLLM::Code::Tools.all(sandbox).to_h { |tool| [tool.name, tool] }
  end

  def screen
    @screen ||= StringIO.new
  end

  def ui
    @ui ||= RubyLLM::Code::UI.new(out: screen, input: StringIO.new, color: false)
  end

  def cleanup_sandbox
    FileUtils.remove_entry(@sandbox.root) if @sandbox
  end
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |expectations| expectations.syntax = :expect }
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.order = :random
  Kernel.srand config.seed

  config.include Sandbox
  config.after { cleanup_sandbox }
end
