module GitBundle
  module Commands
    class Checkout
      include GitBundle::Console

      def initialize(project, args)
        @project = project
        @args = args
      end

      def invoke
        @project.load_dependant_repositories

        if @args.empty?
          checkout_parallel(@project.dependant_repositories, @project.main_repository.branch)

        elsif @args.size == 1
          if checkout(@project.main_repository, @args.first)
            checkout_parallel(@project.dependant_repositories, @args.first)
          end
        elsif @args.size == 2 && @args.first == '-b'
          if checkout(@project.main_repository, @args.last, create_new: true, force: true)
            @project.dependant_repositories.each {|r| checkout(r, @args.last, create_new: true)}
          end
          @project.branch_config.save if @project.branch_config.changed?
        elsif @args.size == 2 && (@args.first == '-a' || @args.first == '--all')
          if checkout(@project.main_repository, @args.last)
            @project.dependant_repositories.each {|r| checkout(r, @args.last)}
          end
          @project.branch_config.save if @project.branch_config.changed?
        else
          puts_error "Invalid arguments for checkout.  Usage: \n\tgitb checkout\n\tgitb checkout <branch>\n\tgitb checkout -b <new branch>\n\tgitb checkout -a <force branch all repositories>"
        end
      end

      def checkout(repo, branch, create_new: false, force: false)
        if create_new
          unless force
            puts_repo_heading(repo)
            puts_prompt("Create #{branch}? (Y/N)")
            return unless STDIN.getch.upcase == 'Y'
          end
          args = ['checkout', '-b', branch]
        else
          args = ['checkout', branch]
        end

        output = repo.execute_git(args, color: true)
        success = $?.exitstatus == 0
        repo.refresh_branch
        puts_repo_heading(repo) unless create_new && !force
        success ? puts(output) : puts_error(output)
        if success && !repo.main && @project.branch_config.current && @project.branch_config.current[repo.name] != branch
          @project.branch_config.current[repo.name] = branch
        end
        success
      end

      def checkout_parallel(repositories, fallback_branch)
        parallel(repositories) do |repo|
          output = repo.execute_git(['checkout', @project.branch_config.current&.dig(repo.name) || fallback_branch], color: true)
          repo.refresh_branch
          ExecutionResult.new($?.exitstatus != 0, output)
        end
      end
    end
  end
end