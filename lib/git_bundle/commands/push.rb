module GitBundle
  module Commands
    class Push
      include GitBundle::Console

      def initialize(repositories, args)
        @repositories = repositories
        @args = args
      end

      def invoke
        return false unless prompt_confirm

        lockfile = Bundler.default_lockfile.basename.to_s
        stale_repos = @repositories.select { |repo| !repo.main && repo.stale? }
        stale_commits_message = stale_repos.map { |repo| "#{repo.name}(#{repo.stale_commits_count})" }.join(', ')

        if stale_repos.any?
          puts "Local gems were updated. Building new #{lockfile} with bundle install."
          unless build_gemfile_lock
            puts_error 'Bundle install failed.  Please run it manually before trying to push changes.'
            return false
          end
        end

        if main_repository.file_changed?(lockfile)
          main_repository.add_file(lockfile)
          if stale_commits_message.empty?
            message = 'Updated Gemfile.lock.'
          else
            message = "Gemfile.lock includes new commits of: #{stale_commits_message}."
          end

          main_repository.commit(message, lockfile)
          puts message
        end

        @repositories.select { |repo| !repo.main && repo.commits_not_pushed_count > 0 }.each do |repo|
          puts_repo_heading(repo)
          unless repo.push(@args)
            puts_error "Failed to push changes of #{repo.name}.  Try pulling the latest changes or resolve conflicts first."
            return false
          end
        end

        puts_repo_heading(main_repository)
        unless main_repository.push(@args)
          puts_error "Failed to push changes of #{main_repository.name}.  Try pulling the latest changes or resolve conflicts first."
        end
      end

      private
      def prompt_confirm
        if main_repository.file_changed?('Gemfile')
          puts_error 'Your Gemfile has uncommitted changes.  Commit them first before pushing.'
          return false
        end

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
          puts_prompt('Are you sure you want to push these changes? (Y/N)')

        elsif gemfile_lock_stale?
          puts_prompt('Although you don\'t have any commits to push, your Gemfile.lock needs to be rebuilt, committed and pushed.')
          puts_prompt('Do you want to continue? (Y/N)')

        elsif main_repository.file_changed?('Gemfile.lock')
          puts_prompt('Although you don\'t have any commits to push, your Gemfile.lock needs to be committed and pushed.')
          puts_prompt('Do you want to continue? (Y/N)')
        else
          return false
        end

        STDIN.getch.upcase == 'Y'
      end

      def main_repository
        @repositories.find { |repo| repo.main }
      end

      def gemfile_lock_stale?
        @repositories.any? { |repo| repo.stale? }
      end

      def build_gemfile_lock
        Dir.chdir(main_repository.path) do
          puts `bundle install --quiet`
          return $?.exitstatus == 0
        end
      end
    end
  end
end
