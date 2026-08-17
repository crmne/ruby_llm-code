# frozen_string_literal: true

require 'open3'
require 'timeout'

module RubyLLM
  module Code
    module Tools
      # Runs a command in the workspace. Needs a yes, every time, because this
      # is the tool that can do anything.
      class Shell < Base
        requires_approval

        DEFAULT_TIMEOUT = 120
        MAX_TIMEOUT = 600
        MAX_OUTPUT = 30_000

        description <<~TEXT
          Run a shell command from the workspace root and return its combined
          output and exit status. Use it for tests, git, linters, and build tools.
          Prefer the read, list, glob, and grep tools for looking at files.
        TEXT

        parameter :command, description: 'The command line to run'
        parameter :timeout, type: :integer, required: false,
                            description: "Seconds to wait before giving up. Defaults to #{DEFAULT_TIMEOUT}"

        def self.label(arguments) = arguments[:command]

        # A short command is already legible in the approval line; a long or
        # multi-line one needs room of its own.
        def self.preview(arguments)
          command = arguments[:command].to_s
          fence(command, 'sh') if command.length > 60 || command.include?("\n")
        end

        def execute(command:, timeout: DEFAULT_TIMEOUT)
          output, status = run(command.to_s, timeout.to_i.clamp(1, MAX_TIMEOUT))
          body = output.strip.empty? ? '(no output)' : clamp(output.strip, MAX_OUTPUT)
          status.zero? ? body : "exit status #{status}\n#{body}"
        rescue SystemCallError => e
          { error: e.message }
        end

        private

        def run(command, seconds)
          Open3.popen2e(command, chdir: workspace.root.to_s, pgroup: true) do |stdin, out, wait|
            stdin.close
            begin
              output = Timeout.timeout(seconds) { out.read }
              [output, wait.value.exitstatus || 0]
            rescue Timeout::Error
              terminate(wait.pid)
              raise ToolError, "timed out after #{seconds}s: #{command}"
            end
          end
        end

        def terminate(pid)
          Process.kill('-TERM', Process.getpgid(pid))
        rescue Errno::ESRCH, Errno::EPERM
          nil # already gone
        end
      end
    end
  end
end
