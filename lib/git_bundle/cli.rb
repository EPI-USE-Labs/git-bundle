module GitBundle
  class CLI
    include GitBundle::Console

    def initialize
      @errors = []
      load_repositories
    end

    def invoke(args)
      case args[0]
        when nil, '--help', 'help'
          puts `git #{args.join(' ')}`.gsub('git', 'gitb')
        when 'push'
          GitBundle::Commands::Push.new(@repositories, args[1..-1]).invoke
        else
          GitBundle::Commands::Generic.new(@repositories, args).invoke
      end
    end

    private
    def load_repositories
      @repositories = []
      if Bundler.locked_gems
        Bundler.settings.local_overrides.each do |name, path|
          spec = Bundler.locked_gems.specs.find { |s| s.name == name }
          @repositories << GitBundle::Repository.new_dependant(spec.name, path, spec.source.branch, spec.source.revision) if spec
        end
      end

      @repositories << GitBundle::Repository.new_main(File.basename(Dir.getwd), Dir.getwd)
    end
  end
end
