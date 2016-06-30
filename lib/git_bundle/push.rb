module GitBundle
  class Push
    include GitBundle::Console

    def initialize(repositories, args)
      @repositories = repositories
      @args = args
    end

    def prompt_confirm
      commits_to_push = false

      @repositories.each do |repo|
        commits = repo.commits_not_pushed
        puts_repo_heading(repo)

        if commits.empty?
          puts 'No changes.'
        else
          commits_to_push = true
          puts commits
        end
      end

      if commits_to_push
        puts_prompt("\nAre you sure you want to push these changes? (Y/N)")
        STDIN.getch.upcase == 'Y'

      elsif main_repository.file_changed?('Gemfile.lock')
        puts_prompt("\nAlthough you don't have any commits to push, your Gemfile.lock needs to be rebuilt, committed and pushed.")
        puts_prompt('Do you want to continue? (Y/N)')
        STDIN.getch.upcase == 'Y'
      end
    end

    def invoke
      @repositories.each do |repo|
        if repo.locked_branch != repo.branch
          puts_error "\nThe git revisions of #{repo.name} does not match.  Are you running the correct branch?"
          puts_error "You are running #{repo.name} branch: #{repo.branch}"
          puts_error "Gemfile.lock references: #{repo.locked_branch}"
          return
        end
      end

      message = @repositories.map { |repo| repo.commit_messages_not_pushed }.uniq.join("\n\n")
      @repositories.reject { |repo| repo.main || repo.commits_not_pushed.empty? }.each do |repo|
        puts_repo_heading(repo)
        unless repo.push(@args)
          puts_error "Failed to push changes of #{repo.name}.  Try pulling the latest changes or resolve conflicts first."
          return
        end
      end

      puts_repo_heading(main_repository)
      repo_changes = @repositories.any? { |repo| repo.revision == repo.locked_revision }

      build_gemfile_lock if repo_changes
      if main_repository.file_changed?('Gemfile.lock')
        main_repository.add_file('Gemfile.lock')
        main_repository.commit("Updated Gemfile.lock to include changes: #{commit_message}", 'Gemfile.lock')
      end

      main_repository.push(@args)
    end

    private
    def main_repository
      @repositories.find { |repo| repo.main }
    end

    def build_gemfile_lock
      puts 'Local gems were updated. Building new Gemfile.lock with bundle install.'
      Dir.chdir(main_repository.path) do
        puts `bundle install --quiet`
        $?.exitstatus == 0
      end
    end
  end
end