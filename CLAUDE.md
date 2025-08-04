# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RubyLLM Code is a Ruby implementation of Claude Code - an AI-powered command-line interface for software development assistance. It emphasizes minimal dependencies, clean architecture, and excellent developer experience.

## Essential Commands

### Development Setup
```bash
bundle install              # Install dependencies
bundle check               # Verify dependencies are satisfied
```

### Running the CLI
```bash
./bin/rubyllm              # Run locally during development
bundle exec ruby bin/rubyllm   # Alternative local execution
```

### Testing
```bash
bundle exec rake spec      # Run full test suite
bundle exec rake          # Default task - runs tests
bundle exec rake coverage  # Run tests with coverage report
```

### Code Quality
```bash
bundle exec standardrb     # Run linting and formatting checks
bundle exec standardrb --fix   # Auto-fix linting issues
```

## Architecture Overview

The codebase follows a clean architecture pattern with single-responsibility classes:

- **CLI Entry Points**: `lib/rubyllm_cli/cli.rb` handles command-line parsing and mode selection (interactive vs non-interactive)
- **Tool System**: All AI capabilities are implemented as tools extending `BaseTool` in `lib/rubyllm_cli/tools/`
- **Workspace Management**: `Workspace` class enforces safe file system boundaries and respects gitignore
- **Configuration**: Flexible configuration system supporting YAML files, environment variables, and CLI options
- **Memory System**: Persistent conversation memory stored in `~/.rubyllm/memories/`

## Key Development Patterns

1. **Tool Development**: New tools should extend `BaseTool` and implement `name`, `description`, `parameters_schema`, and `execute` methods
2. **Testing**: Use RSpec with temporary directories for file system operations. Mock RubyLLM responses using test helpers
3. **Error Handling**: Tools should raise descriptive errors that get properly formatted for users
4. **Streaming**: Support streaming responses by yielding chunks in tool implementations

## Configuration

Default configuration location: `~/.rubyllm/config.yml`

Key environment variables:
- `RUBYLLM_MODEL`: Override the AI model selection
- `DEBUG`: Enable debug output when set to "1"

## Dependencies

Core runtime dependencies are minimal:
- `ruby_llm` for LLM integration
- `ruby_llm-mcp` for MCP server support
- `zeitwerk` for code loading

All other functionality uses Ruby's standard library.