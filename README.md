# RubyLLM Code

A Ruby implementation of Claude Code. Because if we're going to have AI assistants, they should speak Ruby.

## What it is

This is Claude Code, reimagined in Ruby. Same powerful AI assistance, but with the elegance and simplicity Ruby developers expect. No bloat, no enterprise patterns, just clean Ruby code that gets the job done.

## Installation

```bash
gem install ruby_llm-code
```

Or clone and run:
```bash
bundle install
./bin/rubyllm
```

## Usage

Start a conversation:
```bash
rubyllm
```

Ask a question:
```bash
rubyllm "What files are in this directory?"
```

Pipe input:
```bash
cat app.rb | rubyllm "Explain this code"
```

## Philosophy

This isn't just another CLI tool. It's Claude Code, built the Ruby way:

- **Minimal dependencies** - RubyLLM, Zeitwerk, and stdlib. That's it.
- **Clear intentions** - Each class has one job and does it well.
- **Convention over configuration** - It just works out of the box.
- **Developer happiness** - Beautiful syntax highlighting, thoughtful formatting.

## The Tools

We kept what matters:
- File operations (read, write, edit)
- Shell execution 
- Web search and fetching
- Memory that persists
- MCP server support

Each tool does one thing well. Unix philosophy meets AI assistance.

## Configuration

Drop a `~/.rubyllm/config.yml` if you need to:

```yaml
model: claude-3-5-sonnet-20241022
temperature: 0.7
tools_enabled: true
```

Or just use environment variables. We respect `RUBYLLM_MODEL` and the usual API keys.

## Why This Exists

Because Claude Code is brilliant, but it should be in Ruby. Because AI tools should follow the principles that make Ruby great. Because comprehensive doesn't mean complicated.

This is opinionated software. It makes choices so you don't have to.

## License

MIT. Use it, fork it, make it better.

---

*Built with love for the Ruby community. DHH would be proud.*