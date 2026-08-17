# RubyLLM Code

A coding agent in your terminal, in about 1300 lines of Ruby. Seven tools, one prompt, and a second model you can call in when the first one is guessing.

Built on [RubyLLM](https://rubyllm.com) 2.0, which owns the hard parts: the agentic loop, tool approval, seventeen providers behind one API. Dressed by [Charm for Ruby](https://charm-ruby.dev) — Lipgloss for the frames, Glamour for the markdown.

## Install

RubyLLM 2.0 is still in development, so this tracks its trunk and is not on RubyGems yet. Clone it:

```bash
git clone https://github.com/crmne/ruby_llm-code
cd ruby_llm-code
bundle install
```

Export a key for whichever provider you like and it picks a model that key can reach:

```bash
export ANTHROPIC_API_KEY=sk-...   # or OPENAI_API_KEY, GEMINI_API_KEY, ...
```

Every credential RubyLLM's providers know about is read straight from the environment, so however you already manage keys — direnv, dotenv, mise, a password manager — keeps working. Nothing reads a `.env` on its own.

## Use

```bash
./bin/rubyllm                                  # start a session
./bin/rubyllm "why is this spec flaky?"         # ask once and leave
cat error.log | ./bin/rubyllm "explain this"    # pipe something in
```

Inside a session:

| command | what it does |
| --- | --- |
| `/model [id]` | show the model, or switch to another one |
| `/collab [id] [rounds]` | put a second model on every task, or turn it off |
| `/tools` | the tools the agent has, and which ones ask first |
| `/cost` | tokens and dollars so far |
| `/diff` | what has changed in the working tree |
| `/clear` | forget the conversation, keep the setup |
| `/yolo` | approve every tool call from here on |
| `/exit` | leave |

## Two models, one task

```
❯ /collab gpt-5.4
  collab · claude-sonnet-5 + gpt-5.4 · 2 rounds

❯ make the cache invalidate on write
```

Both models now work the same task, and you watch it happen:

```
explore ───────────────────────────────────────────────
 A  claude-sonnet-5  ⠹  read lib/cache.rb
 B  gpt-5.4          ⠹  grep "def write"
```

They are two `RubyLLM::Agent`s with read-only tools, each one an `Async` task, so the two conversations overlap instead of taking turns — the [parallel workflow](https://rubyllm.com/advanced/agentic-workflows/#parallel-workflow) from the RubyLLM guides, pointed at a codebase. Then:

1. **explore** — both read the code and open with a proposal, at the same time.
2. **debate** — each answers the other, starting with `AGREED:` or `REVISE:`. Agreement ends it early; otherwise it runs the rounds you asked for.
3. **plan** — the agent that opened writes the plan they settled on, and says what it dropped.
4. **implement** — the coder, the only agent with `write`, `edit`, and `shell`, does the work and asks you before each change.
5. **review** — the *other* model reads the diff it did not write. `LGTM:` ends the turn; `ISSUES:` sends the coder back in.

The whole turn is one `RubyLLM.workflow`, so every call in it is correlated in your instrumentation, phase by phase.

Two models disagreeing about your code is the point. They read different things, catch different mistakes, and you get the argument instead of the first plausible answer.

## Nothing happens without a yes

`write`, `edit`, and `shell` are declared `requires_approval`, so the loop parks and shows you what it wants to do:

```
⏵ edit(lib/cache.rb)
  - def write(key, value)
  + def write(key, value, invalidate: true)
  approve? [y]es [n]o [a]lways
```

`read`, `list`, `glob`, and `grep` just run. Pass `--yolo` (or `/yolo`) when you would rather not be asked.

Everything stays inside the workspace: a path that climbs out is refused before the tool sees it.

## How it fits together

```
lib/ruby_llm/code/
  cli.rb          flags, then one question or the whole REPL
  session.rb      one sitting: turns, streaming, approvals
  collab.rb       two models on one task
  coder.rb        the agent that writes
  peer.rb         the agents that read and argue
  commands.rb     the slash commands
  tools/          read list glob grep · write edit shell
  prompts/        every word the agents are told, in ERB
  ui.rb           lipgloss + glamour
```

The prompts are plain ERB files rendered through RubyLLM's prompt templates, and your own `app/prompts` is searched first — so dropping a `coder.txt.erb` in your project overrides the agent's instructions without touching this gem.

## Develop

```bash
bundle exec rspec      # tests, no network
bundle exec rubocop    # lint
```

## License

MIT.
