# frozen_string_literal: true

module RubyLLM::Code
  class Workspace
    attr_reader :root
    
    def initialize(root = Dir.pwd)
      @root = File.expand_path(root)
      @gitignore = GitIgnore.new(@root)
    end
    
    def within?(path)
      expanded = File.expand_path(path)
      expanded.start_with?(@root)
    end
    
    def relative_path(path)
      Pathname.new(File.expand_path(path)).relative_path_from(Pathname.new(@root)).to_s
    rescue
      path
    end
    
    def absolute_path(path)
      if Pathname.new(path).absolute?
        path
      else
        File.join(@root, path)
      end
    end
    
    def ignored?(path)
      @gitignore.ignored?(relative_path(path))
    end
    
    def git?
      File.exist?(File.join(@root, ".git"))
    end
  end
  
  class GitIgnore
    def initialize(root)
      @root = root
      @patterns = load_patterns
    end
    
    def ignored?(path)
      return false if @patterns.empty?
      
      @patterns.any? { |pattern| File.fnmatch?(pattern, path, File::FNM_PATHNAME) }
    end
    
    private
    
    def load_patterns
      gitignore_path = File.join(@root, ".gitignore")
      rubyllm_ignore_path = File.join(@root, ".rubyllm", "ignore")
      
      patterns = []
      patterns.concat(parse_ignore_file(gitignore_path)) if File.exist?(gitignore_path)
      patterns.concat(parse_ignore_file(rubyllm_ignore_path)) if File.exist?(rubyllm_ignore_path)
      patterns
    end
    
    def parse_ignore_file(path)
      File.readlines(path)
        .map(&:strip)
        .reject { |line| line.empty? || line.start_with?("#") }
    rescue
      []
    end
  end
end