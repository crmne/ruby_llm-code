# frozen_string_literal: true

module RubyLLMCLI
  module Colors
    # Check if colors are supported
    COLORS_ENABLED = ENV['NO_COLOR'].nil? && 
                     ENV['TERM'] != 'dumb' && 
                     ($stdout.tty? || ENV['FORCE_COLOR'])
    
    # ANSI color codes
    RESET = COLORS_ENABLED ? "\e[0m" : ""
    BOLD = COLORS_ENABLED ? "\e[1m" : ""
    DIM = COLORS_ENABLED ? "\e[2m" : ""
    STRIKETHROUGH = COLORS_ENABLED ? "\e[9m" : ""
    
    # Colors
    BLACK = COLORS_ENABLED ? "\e[30m" : ""
    RED = COLORS_ENABLED ? "\e[31m" : ""
    GREEN = COLORS_ENABLED ? "\e[32m" : ""
    YELLOW = COLORS_ENABLED ? "\e[33m" : ""
    BLUE = COLORS_ENABLED ? "\e[34m" : ""
    MAGENTA = COLORS_ENABLED ? "\e[35m" : ""
    CYAN = COLORS_ENABLED ? "\e[36m" : ""
    WHITE = COLORS_ENABLED ? "\e[37m" : ""
    
    # Bright colors
    BRIGHT_BLACK = COLORS_ENABLED ? "\e[90m" : ""
    BRIGHT_RED = COLORS_ENABLED ? "\e[91m" : ""
    BRIGHT_GREEN = COLORS_ENABLED ? "\e[92m" : ""
    BRIGHT_YELLOW = COLORS_ENABLED ? "\e[93m" : ""
    BRIGHT_BLUE = COLORS_ENABLED ? "\e[94m" : ""
    BRIGHT_MAGENTA = COLORS_ENABLED ? "\e[95m" : ""
    BRIGHT_CYAN = COLORS_ENABLED ? "\e[96m" : ""
    BRIGHT_WHITE = COLORS_ENABLED ? "\e[97m" : ""
    
    # Semantic colors
    PROMPT = BRIGHT_BLACK
    TOOL_NAME = BRIGHT_BLUE
    TOOL_ARGS = BRIGHT_BLACK
    TOOL_RESULT = DIM
    ERROR = RED
    SUCCESS = GREEN
    WARNING = YELLOW
    INFO = CYAN
    COMMAND = BRIGHT_MAGENTA
    MODEL = BRIGHT_CYAN
    TYPING = DIM
    
    def self.colorize(text, color)
      "#{color}#{text}#{RESET}"
    end
    
    def self.prompt(text)
      colorize(text, PROMPT)
    end
    
    def self.tool(text)
      colorize(text, TOOL_NAME)
    end
    
    def self.dim(text)
      colorize(text, DIM)
    end
    
    def self.error(text)
      colorize(text, ERROR)
    end
    
    def self.success(text)
      colorize(text, SUCCESS)
    end
    
    def self.info(text)
      colorize(text, INFO)
    end
    
    def self.command(text)
      colorize(text, COMMAND)
    end
    
    def self.model(text)
      colorize(text, MODEL)
    end
    
    def self.strikethrough(text)
      colorize(text, STRIKETHROUGH)
    end
  end
end