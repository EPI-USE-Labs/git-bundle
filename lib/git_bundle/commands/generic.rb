module GitBundle
  module Commands
    class Generic
      include GitBundle::Console

      def initialize(project, args)
        @project = project
        @args = args
      end

      def invoke
        @project.load_dependant_repositories

        parallel(@project.repositories) do |repo|
          output = repo.execute_git(@args, color: true)
          ExecutionResult.new($?.exitstatus != 0, output)
        end
      end
    end
  end
end