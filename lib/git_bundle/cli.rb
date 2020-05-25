module GitBundle
  class CLI
    include GitBundle::Console

    def initialize
      @errors = []
      @project = GitBundle::Project.new
    end

    def invoke(args)
      case args[0]
      when nil, '--help', 'help'
        puts `git #{args.join(' ')}`.gsub('git', 'gitb')
      when 'push'
        GitBundle::Commands::Push.new(@project, args[1..-1]).invoke
      when 'checkout'
        GitBundle::Commands::Checkout.new(@project, args[1..-1]).invoke
      when 'generate', 'g'
        GitBundle::Commands::Generate.new(@project, args[1..-1]).invoke
      when '--version'
        GitBundle::Commands::Version.new.invoke
      else
        GitBundle::Commands::Generic.new(@project, args).invoke
      end
    rescue Bundler::GemfileNotFound => e
      puts_error("Could not find Gemfile in the current directory")
    end
  end
end
