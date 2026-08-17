# CLAUDE.md

Guidance for agents working in this repository.

## What this is

RubyLLM Code is a small coding agent for the terminal, built on RubyLLM 2.0. Its
one distinctive feature is `/collab <model>`: two models work the same task,
explore the workspace in parallel, argue until they agree, and only then does the
coder touch the files.

## Commands

```bash
bundle install
./bin/rubyllm                 # run it
bundle exec rspec             # tests, no network needed
bundle exec rubocop           # lint
bundle exec rake              # both
```

RubyLLM 2.0 is unreleased, so the Gemfile tracks its trunk.

## Layout

- `lib/ruby_llm/code/cli.rb` — flags, then either one question or the REPL
- `lib/ruby_llm/code/session.rb` — one sitting: turns, streaming, approvals
- `lib/ruby_llm/code/collab.rb` — the two-model workflow
- `lib/ruby_llm/code/coder.rb`, `peer.rb` — the two `RubyLLM::Agent` subclasses
- `lib/ruby_llm/code/tools/` — `read list glob grep` and `write edit shell`
- `lib/ruby_llm/code/prompts/` — every word the agents are told, as ERB
- `lib/ruby_llm/code/ui.rb` — Lipgloss frames, Glamour markdown, one write mutex

## Conventions

- **Lean on RubyLLM.** The agentic loop (`ask_later`, `complete`, `step`), tool
  approval (`requires_approval`, `approve!`, `deny!`), the usage ledger
  (`chat.tokens`, `chat.cost`), prompt templates, and `RubyLLM.workflow` are all
  already there. Do not reimplement them here.
- **Prompts are files.** Behaviour changes belong in `prompts/*.txt.erb`, not in
  Ruby heredocs. A project's own `app/prompts` overrides them.
- **Tools stay small.** One job each, `{ error: "..." }` for anything the model
  should read and correct, `raise ToolError` for a refusal. Anything that changes
  the workspace declares `requires_approval` and a `preview`.
- **Every path goes through `Workspace#resolve`,** which refuses to leave the
  workspace.
- **All output goes through `UI`.** Nothing else prints; a spinner runs in its own
  thread and the mutex in `UI#write` is what keeps lines intact.
- Plain Ruby, small methods, no ceremony. Comments explain why, not what.

## Testing

Specs never hit the network. Stub `RubyLLM::Code::Peer.new` to script a
collaboration, and stub the coder's loop verbs to script a turn. `spec_helper.rb`
gives every example a throwaway `sandbox` workspace and a `ui` writing to a
`screen` you can read back.
