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
      @branch ||= execute_git('rev-parse --abbrev-ref HEAD')
    end

    def locked_branch
      @locked_branch || branch
    end

    def revision
      @revision ||= execute_git('rev-parse --verify HEAD').gsub("\n", '')
    end

    def locked_revision
      @locked_revision || revision
    end

    def commits_not_pushed
      execute_git("rev-list --pretty=oneline --abbrev-commit origin/#{branch}..#{branch}")
    end

    def commit_messages_not_pushed
      count = execute_git("rev-list origin/#{branch}..#{branch} --count").to_i
      count.times.map { |num| execute_git("rev-list --pretty=oneline --skip=#{num} --max-count=1 origin/#{branch}..#{branch}").sub(/\h*\s/, '').strip }
    end

    def push(args)
      puts execute_git("push #{args.join(' ')}")
      $?.exitstatus == 0
    end

    def file_changed?(filename)
      !execute_git("diff --name-only #{filename}").empty? && $?.exitstatus == 0
    end

    def add_file(filename)
      execute_git("add #{filename}")
      $?.exitstatus == 0
    end

    def commit(message, *files)
      execute_git("commit -m '#{message}' #{files.join(' ')}")
      $?.exitstatus == 0
    end

    def execute_git(command)
      full_command = "git -C #{@path} #{command}"
      puts full_command if ENV['DEBUG'] == 'true'
      `#{full_command}`.strip
    end
  end
end