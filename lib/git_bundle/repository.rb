module GitBundle
  class Repository
    include GitBundle::Shell

    attr_reader :name,
                :path,
                :main,
                :branch,
                :locked_branch

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
      refresh_branch
    end

    def refresh_branch
      @branch = execute_git('rev-parse', '--abbrev-ref', 'HEAD').chomp
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

    def reference_exists?(reference)
      execute_git('cat-file', '-e', reference)
      $?.exitstatus == 0
    end

    def upstream_branch_exists?
      reference_exists?("origin/#{branch}")
    end

    def stale_commits
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', "#{locked_revision}..#{revision}")
    end

    def stale_commits_count
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', '--count', "#{locked_revision}..#{revision}").to_i
    end

    def commits_not_pushed?
      return true unless upstream_branch_exists?
      commits_not_pushed_count > 0
    end

    def commits_not_pushed
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', "origin/#{branch}..#{branch}")
    end

    def commits_not_pushed_count
      execute_git('rev-list', '--pretty=oneline', '--abbrev-commit', '--count', "origin/#{branch}..#{branch}").to_i
    end

    def push(args, create_upstream: false)
      args = args.dup + ['--set-upstream', 'origin', branch] if create_upstream
      execute_git_output('push', args)
      $?.exitstatus == 0 || (create_upstream && $?.exitstatus == 128)
    end

    def checkout(args)
      execute_git_output('checkout', args)
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

    def commit_with_description(message, description, *files)
      execute_git('commit', '-m', message, '-m', description, files)
      $?.exitstatus == 0
    end

    def git_command(*args, **options)
      git_command = ['git', '-C', @path]
      git_command += %w(-c color.status=always -c color.ui=always) if options.fetch(:color, false)
      git_command + args.flatten
    end

    def execute_git(*args, **options)
      execute(*git_command(*args, **options))
    end

    def execute_git_output(*args, **options)
      execute_live(*git_command(*args, **options))
    end
  end
end