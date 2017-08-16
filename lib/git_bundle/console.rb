module GitBundle
  module Console
    COLORS = {error: 31,
              attention: 32,
              prompt: 33,
              heading: 34,
              highlight: 36}

    def clear_line
      STDOUT.print "\r\e[0K"
      STDOUT.flush
    end

    def puts_repo_heading(repo)
      puts colorize("\n=== #{repo.name} (#{repo.branch})", COLORS[:heading], true)
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
    def colorize(text, color_code, bold = false)
      if bold
        "\e[1m\e[#{color_code}m#{text}\e[0m"
      else
        "\e[#{color_code}m#{text}\e[0m"
      end
    end
  end
end