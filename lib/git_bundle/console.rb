module GitBundle
  module Console
    COLORS = {std: 0,
              error: 31,
              attention: 32,
              prompt: 33,
              heading: 36}

    def puts_repo_heading(repo)
      puts_heading "#{repo.name} (#{repo.branch})"
    end

    def puts_heading(text)
      puts colorize("\n=== #{text}", COLORS[:heading])
    end

    def puts_attention(text)
      puts colorize(text, COLORS[:attention])
    end

    def puts_prompt(text)
      puts colorize(text, COLORS[:prompt])
    end

    def puts_error(text)
      puts colorize(text, COLORS[:error])
    end

    private
    def colorize(text, color_code)
      "\e[#{color_code}m#{text}\e[0m"
    end
  end
end