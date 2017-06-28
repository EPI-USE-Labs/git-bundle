module GitBundle
  class Repository
    attr_reader :name,
                :path,
                :main

    def self.new_main(name, path)
      GitBundle::Repository.new(name, path, true, nil, nil)
    end

    def self.new_dependant(name, path, locked_branch, locked_revision)
      GitBundle::Repository.new(name, path, false, locked_branch, locked_revision)
    end

    def initialize(name, path, main_repository, locked_branch, locked_revision)
      @name = name
      @path = path
      @main = main_repository
      @locked_branch = locked_branch
      @locked_revision = locked_revision
    end

    def branch
      @branch ||= execute_git('rev-parse', '--abbrev-ref', 'HEAD').chomp
    end

    def locked_branch
      @locked_branch || branch
    end

    def revision
      @revision ||= execute_git('rev-parse', '--verify', 'HEAD').gsub("\n", '')
    end

    def locked_revision
      @locked_revision || revision
    end

    def stale?
      revision != locked_revision
    end

    def stale_commits
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', "#{locked_revision}..#{revision}")
    end

    def stale_commits_count
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', '--count', "#{locked_revision}..#{revision}").to_i
    end

    def commits_not_pushed
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', "origin/#{branch}..#{branch}")
    end

    def commits_not_pushed_count
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', '--count', "origin/#{branch}..#{branch}").to_i
    end

    def push(args)
      puts execute_git('push', args)
      $?.exitstatus == 0
    end

    def file_changed?(filename)
      !execute_git('diff', '--name-only', filename).empty? && $?.exitstatus == 0
    end

    def add_file(filename)
      execute_git('add', filename)
      $?.exitstatus == 0
    end

    def commit(message, *files)
      execute_git('commit', '-m', message, files)
      $?.exitstatus == 0
    end

    def execute_git(*args, **options)
      git_command = ['git', '-C', @path]
      git_command += %w(-c color.status=always -c color.ui=always) if options.fetch(:color, false)
      git_command += args.flatten
      execute(*git_command)
    end

    def execute(*args)
      puts args.map{ |arg| "'#{arg}'" }.join(' ') if ENV['DEBUG'] == 'true'

      pipe_out, pipe_in = IO.pipe
      system *args, out: pipe_in, err: pipe_in
      pipe_in.close
      pipe_out.read
    end
  end
end