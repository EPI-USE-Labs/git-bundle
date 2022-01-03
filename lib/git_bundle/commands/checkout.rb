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
        remaining_args = @args.dup
        flag = remaining_args.first&.chars&.first == "-" ? remaining_args.shift : nil
        branch = remaining_args.shift

        if remaining_args.any? || (flag && branch.nil?)
          puts_error "Invalid arguments for checkout.  Usage: \n\tgitb checkout\n\tgitb checkout <branch>\n\tgitb checkout <remote/branch>\n\tgitb checkout -b <new branch>\n\tgitb checkout -a <force branch all repositories>"
          return
        end

        case
        when flag == "-a" || flag == "--all"
          if checkout(@project.main_repository, branch)
            @project.dependant_repositories.each { |r| checkout(r, branch) }
          end
          @project.branch_config.save if @project.branch_config.changed?
        when flag == "-b"
          if checkout(@project.main_repository, branch, create_new: true, force: true)
            @project.dependant_repositories.each { |r| checkout(r, branch, create_new: true) }
          end
          @project.branch_config.save if @project.branch_config.changed?
        when branch.nil?
          checkout_parallel(@project.dependant_repositories, fallback_branch: @project.main_repository.branch)
        else
          if checkout(@project.main_repository, branch)
            checkout_parallel(@project.dependant_repositories, fallback_branch: branch)
          end
        end
      end

      def checkout(repo, branch, create_new: false, force: false)
        args = ['checkout']
        if create_new
          unless force
            puts_repo_heading(repo)
            puts_prompt("Create #{branch}? (Y/N)")
            return unless STDIN.getch.upcase == 'Y'
          end
          args << '-b'
        end
        args << branch

        output = repo.execute_git(args, color: true)
        success = $?.exitstatus == 0
        repo.refresh_branch
        puts_repo_heading(repo) unless create_new && !force
        if success && !repo.main && create_new && @project.branch_config.current
          old_remote = @project.branch_config.remote(repo.name)
          if old_remote
            @project.branch_config.current[repo.name] = "#{old_remote} #{branch}"
          else
            @project.branch_config.current[repo.name] = branch
          end
          puts(output)
        else
          puts_error(output)
        end
        success
      end

      def checkout_parallel(repositories, fallback_branch: nil)
        parallel(repositories) do |repo|
          output = repo.execute_git(['checkout', @project.branch_config.branch(repo.name) || fallback_branch], color: true)
          repo.refresh_branch
          ExecutionResult.new($?.exitstatus != 0, output)
        end
      end
    end
  end
end