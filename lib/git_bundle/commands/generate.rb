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
        @project.dependant_repositories.each {|p| @project.branch_config.current[p.name] = p.branch}
        @project.branch_config.save
      end
    end
  end
end