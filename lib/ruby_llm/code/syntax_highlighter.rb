# frozen_string_literal: true

module RubyLLM
  module Code
    # rubocop:disable Style/Documentation
    class SyntaxHighlighter
      # Language mappings for common extensions
      LANGUAGE_MAP = {
        'rb' => 'ruby',
        'py' => 'python',
        'js' => 'javascript',
        'ts' => 'typescript',
        'jsx' => 'javascript',
        'tsx' => 'typescript',
        'cpp' => 'cpp',
        'c' => 'c',
        'h' => 'c',
        'hpp' => 'cpp',
        'cs' => 'csharp',
        'java' => 'java',
        'go' => 'go',
        'rs' => 'rust',
        'php' => 'php',
        'swift' => 'swift',
        'kt' => 'kotlin',
        'scala' => 'scala',
        'r' => 'r',
        'm' => 'objective-c',
        'pl' => 'perl',
        'lua' => 'lua',
        'vim' => 'vim',
        'sh' => 'bash',
        'bash' => 'bash',
        'zsh' => 'bash',
        'fish' => 'fish',
        'ps1' => 'powershell',
        'yml' => 'yaml',
        'yaml' => 'yaml',
        'toml' => 'toml',
        'json' => 'json',
        'xml' => 'xml',
        'html' => 'html',
        'htm' => 'html',
        'css' => 'css',
        'scss' => 'scss',
        'sass' => 'sass',
        'less' => 'less',
        'sql' => 'sql',
        'md' => 'markdown',
        'markdown' => 'markdown',
        'tex' => 'latex',
        'dockerfile' => 'dockerfile'
      }.freeze

      # Simple syntax highlighting patterns
      PATTERNS = {
        ruby: {
          keywords: /\b(def|end|class|module|if|unless|elsif|else|case|when|while|until|for|break|next|redo|retry|return|yield|super|self|nil|true|false|and|or|not|in|do|begin|rescue|ensure|raise|attr_reader|attr_writer|attr_accessor|alias|require|require_relative|include|extend|private|protected|public)\b/, # rubocop:disable Layout/LineLength
          strings: /("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`)/,
          symbols: /:[a-zA-Z_]\w*/,
          numbers: /\b\d+(\.\d+)?\b/,
          comments: /#.*/,
          constants: /\b[A-Z][A-Z0-9_]*\b/,
          instance_vars: /@[a-zA-Z_]\w*/,
          class_vars: /@@[a-zA-Z_]\w*/,
          globals: /\$[a-zA-Z_]\w*/
        }
      }.freeze

      def self.highlight(text, _language = nil)
        return text unless Colors::COLORS_ENABLED

        # Handle code blocks
        highlighted = text.gsub(/```(\w+)?\n(.*?)\n```/m) do |_match|
          lang = ::Regexp.last_match(1) || 'text'
          code = ::Regexp.last_match(2)

          # Normalize language name
          lang = LANGUAGE_MAP[lang.downcase] || lang.downcase

          # Apply syntax highlighting
          highlighted_code = highlight_code(code, lang)

          # Format the code block
          "#{Colors.dim("```#{lang}")}\n#{highlighted_code}\n#{Colors.dim('```')}"
        end

        # Handle inline code
        highlighted = highlighted.gsub(/`([^`]+)`/) do |_match|
          code = ::Regexp.last_match(1)
          Colors.colorize("`#{code}`", Colors::BRIGHT_BLACK)
        end

        # Handle markdown formatting
        highlight_markdown(highlighted)
      end

      def self.highlight_code(code, language)
        patterns = PATTERNS[language.to_sym]
        return code unless patterns

        # Apply highlighting in order of precedence
        highlighted = code.dup

        # Comments first (they can contain other patterns)
        if patterns[:comments]
          highlighted.gsub!(patterns[:comments]) do |match|
            Colors.dim(match)
          end
        end

        # Strings (they can contain keywords)
        if patterns[:strings]
          highlighted.gsub!(patterns[:strings]) do |match|
            Colors.colorize(match, Colors::GREEN)
          end
        end

        # Keywords
        if patterns[:keywords]
          highlighted.gsub!(patterns[:keywords]) do |match|
            Colors.colorize(match, Colors::MAGENTA)
          end
        end

        # Constants
        if patterns[:constants]
          highlighted.gsub!(patterns[:constants]) do |match|
            Colors.colorize(match, Colors::YELLOW)
          end
        end

        # Numbers
        if patterns[:numbers]
          highlighted.gsub!(patterns[:numbers]) do |match|
            Colors.colorize(match, Colors::CYAN)
          end
        end

        # Ruby-specific
        if language == 'ruby'
          # Symbols
          highlighted.gsub!(patterns[:symbols]) do |match|
            Colors.colorize(match, Colors::CYAN)
          end

          # Instance variables
          highlighted.gsub!(patterns[:instance_vars]) do |match|
            Colors.colorize(match, Colors::BLUE)
          end

          # Class variables
          highlighted.gsub!(patterns[:class_vars]) do |match|
            Colors.colorize(match, Colors::BLUE)
          end

          # Global variables
          highlighted.gsub!(patterns[:globals]) do |match|
            Colors.colorize(match, Colors::RED)
          end
        end

        highlighted
      end

      def self.highlight_markdown(text)
        # Bold
        text = text.gsub(/\*\*(.*?)\*\*/) do |_match|
          content = ::Regexp.last_match(1)
          Colors.colorize(content, Colors::BOLD)
        end

        # Italic (using dim for terminal)
        text = text.gsub(/\*(.*?)\*/) do |_match|
          content = ::Regexp.last_match(1)
          Colors.dim(content)
        end

        # Headers
        text = text.gsub(/^(#){1,6}\s+(.*)$/) do |_match|
          ::Regexp.last_match(1).length
          content = ::Regexp.last_match(2)
          Colors.colorize(content, Colors::BOLD + Colors::BLUE)
        end

        # Links
        text = text.gsub(/\[([^\]]+)\]\(([^)]+)\)/) do |_match|
          text = ::Regexp.last_match(1)
          url = ::Regexp.last_match(2)
          "#{Colors.colorize(text, Colors::BLUE)} #{Colors.dim("(#{url})")}"
        end

        # Lists
        text.gsub(/^(\s*)([-*+]|\d+\.)\s+(.*)$/) do |_match|
          indent = ::Regexp.last_match(1)
          marker = ::Regexp.last_match(2)
          content = ::Regexp.last_match(3)
          "#{indent}#{Colors.colorize(marker, Colors::YELLOW)} #{content}"
        end
      end
    end
    # rubocop:enable Style/Documentation
  end
end
