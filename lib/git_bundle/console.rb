module GitBundle
  module Console
    COLORS = { error: 31,
               attention: 32,
               prompt: 33,
               heading: 34,
               highlight: 36 }

    ExecutionResult = Struct.new(:error, :output)

    def clear_line
      STDOUT.print "\r\e[0K"
      STDOUT.flush
    end

    def puts_repo_heading(repo)
      puts colorize("\n=== #{repo.name} (#{repo.branch})", COLORS[:heading], true)
    end

    def puts_repo_heading_switch(repo, new_branch)
      puts colorize("\n=== #{repo.name} (#{repo.branch} ⇒ #{new_branch})", COLORS[:heading], true)
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

    def puts_wait_line(names)
      STDOUT.print "Waiting for #{names.map { |name| colorize(name, COLORS[:highlight], true) }.join(', ')}"
      STDOUT.flush
    end

    def parallel(items, heading_proc = nil)
      heading_proc ||= -> (item) { puts_repo_heading(item) }

      item_results = items.map { |item| { item: item, output: '', error: false, complete: false, thread: nil } }

      items.each_with_index do |item, index|
        results = item_results[index]
        results[:thread] = Thread.new do
          result = yield(item)
          results[:output] = result.output
          results[:error] = result.error
        end
      end

      waiting_for_items = items.map(&:name)
      puts_wait_line(waiting_for_items)

      until waiting_for_items.empty?
        item_results.each do |result|
          next if result[:complete]

          if result[:thread].join(0.1)
            result[:complete] = true
            clear_line

            heading_proc.call(result[:item])
            puts result[:output]

            waiting_for_items.delete(result[:item].name)
            puts_wait_line(waiting_for_items) unless waiting_for_items.empty?
          end
        end
      end

      puts ''
      errors = item_results.select { |item| item[:error] }.map { |item| item[:item].name }
      puts_error "Command failed in #{errors.join(', ')}." unless errors.empty?
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