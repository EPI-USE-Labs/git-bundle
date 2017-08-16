module GitBundle
  module Commands
    class Generic
      include GitBundle::Console

      def initialize(repositories, args)
        @repositories = repositories
        @args = args
      end

      def print_wait_line(names)
        STDOUT.print "Waiting for #{names.map {|name| colorize(name, COLORS[:highlight], true)}.join(', ')}"
        STDOUT.flush
      end

      def invoke
        repository_results = @repositories.map {|repo| {repository: repo, output: '', error: false, complete: false, thread: nil}}

        @repositories.each_with_index do |repo, index|
          results = repository_results[index]
          results[:thread] = Thread.new do
            results[:output] = repo.execute_git(@args, color: true)
            results[:error] = true unless $?.exitstatus == 0
          end
        end

        waiting_for_repositories = @repositories.map(&:name)
        print_wait_line(waiting_for_repositories)

        until waiting_for_repositories.empty?
          repository_results.each do |result|
            next if result[:complete]

            if result[:thread].join(0.1)
              result[:complete] = true
              clear_line

              puts_repo_heading(result[:repository])
              puts result[:output]

              waiting_for_repositories.delete(result[:repository].name)
              print_wait_line(waiting_for_repositories) unless waiting_for_repositories.empty?
            end
          end
        end

        puts ''
        errors = repository_results.select {|r| r[:error]}.map {|r| r[:repository].name}
        puts_error "Command failed in #{errors.join(', ')}." unless errors.empty?
      end
    end
  end
end