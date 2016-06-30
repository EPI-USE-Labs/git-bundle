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
          push = GitBundle::Push.new(@repositories, args[1..-1])
          push.invoke if push.prompt_confirm
        else
          exec_all(args)
      end

      puts_error @errors.join('\n') unless @errors.empty?
    end

    def exec_all(*argv)
      exec_errors = []
      @repositories.each do |repo|
        puts_repo_heading(repo)
        puts repo.execute_git(argv.join(' '))
        exec_errors << repo.name unless $?.exitstatus == 0
      end

      @errors << "Command failed in #{exec_errors.join(', ')}." unless exec_errors.empty?
    end

    private
    def load_repositories
      @repositories = []
      begin
        lockfile_content = Bundler.read_file(Bundler.default_lockfile)
        all_specs = Bundler::LockfileParser.new(lockfile_content).specs
        Bundler.settings.local_overrides.each do |name, path|
          spec = all_specs.find { |s| s.name == name }
          @repositories << GitBundle::Repository.new_dependant(spec.name, path, spec.source.branch, spec.source.revision) if spec
        end

      rescue Bundler::LockfileError
        @errors << "Error reading #{Bundler.default_lockfile}: \n\t#{error.message}."
      end

      @repositories << GitBundle::Repository.new_main(File.basename(Dir.getwd), Dir.getwd)
    end
  end
end
