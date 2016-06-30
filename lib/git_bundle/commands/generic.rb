module GitBundle
  module Commands
    class Generic
      include GitBundle::Console

      def initialize(repositories, args)
        @repositories = repositories
        @args = args
      end

      def invoke
        errors = []
        @repositories.each do |repo|
          puts_repo_heading(repo)
          puts repo.execute_git(@args.join(' '))
          errors << repo.name unless $?.exitstatus == 0
        end

        puts_error "Command failed in #{errors.join(', ')}." unless errors.empty?
      end
    end
  end
end