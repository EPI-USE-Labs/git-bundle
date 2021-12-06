module GitBundle
  module Commands
    class Generate
      include GitBundle::Console

      def initialize(project, args)
        @project = project
        @args = args
      end

      def invoke
        @project.load_dependant_repositories
        @project.dependant_repositories.each { |repo| @project.branch_config.current[repo.name] = remote_branch_reference(repo) }
        @project.branch_config.save
      end

      def remote_branch_reference(repository)
        if repository.remote
          "#{repository.remote}/#{repository.branch}"
        else
          repository.branch
        end
      end
    end
  end
end