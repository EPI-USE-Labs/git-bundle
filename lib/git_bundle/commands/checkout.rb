module GitBundle
  module Commands
    class Checkout
      include GitBundle::Console

      def initialize(project, args)
        @project = project
        @args = args
      end

      def invoke
        if checkout(@project.main_repository, @args)
          @project.load_dependant_repositories

          repo_heading_proc = -> (repo) { puts_repo_heading_switch(repo, repo.locked_branch) }
          parallel(@project.dependant_repositories, repo_heading_proc) do |repo|
            output = repo.execute_git('checkout', [repo.locked_branch])
            ExecutionResult.new($?.exitstatus != 0, output)
          end
        else
          puts_error "Command failed in main repository #{@project.main_repository.name}."
        end
      end

      private
      def checkout(repository, args)
        puts_repo_heading_switch(repository, args.first)
        repository.checkout(args)
      end

    end
  end
end