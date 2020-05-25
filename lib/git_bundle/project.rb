module GitBundle
  class Project
    attr_reader :main_repository, :dependant_repositories

    def initialize
      # TODO: Find out how to set Bundler's directory so that the directory can be an argument
      @directory = Dir.getwd
      @main_repository = GitBundle::Repository.new_main(File.basename(@directory), @directory)
    end

    def load_dependant_repositories(locked_branches: true)
      @dependant_repositories = []

      if Bundler.locked_gems
        if locked_branches
          specs = Bundler.locked_gems.specs
        else
          old_value = Bundler.settings[:disable_local_branch_check]
          Bundler.settings[:disable_local_branch_check] = true
          specs = Bundler.definition.specs
          Bundler.settings[:disable_local_branch_check] = old_value
        end

        Bundler.settings.local_overrides.each do |name, path|
          spec = specs.find { |s| s.name == name }
          if spec && spec.source.respond_to?(:branch)
            @dependant_repositories << GitBundle::Repository.new_dependant(spec.name, path, spec.source.branch, spec.source.revision)
          end
        end
      end
    end

    def branch_config
      @branch_config ||= GitBundle::BranchConfig.new
    end

    def repositories
      @dependant_repositories + [@main_repository]
    end
  end
end