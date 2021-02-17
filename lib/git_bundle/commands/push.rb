module GitBundle
  module Commands
    class Push
      include GitBundle::Console
      include GitBundle::Shell

      def initialize(project, args)
        @project = project
        @args = args
      end

      def invoke
        @project.load_dependant_repositories
        return false unless prompt_confirm

        main_repository = @project.main_repository

        lockfile = Bundler.default_lockfile.basename.to_s
        stale_repos = @project.repositories.select { |repo| !repo.main && repo.stale? }
        stale_commits_message = stale_repos.map do |repo|
          repo.upstream_branch_exists? ? "#{repo.name}(#{repo.stale_commits_count})" : "#{repo.name}(new branch)"
        end.join(', ')

        stale_commits_description = ''
        stale_repos.select(&:upstream_branch_exists?).each do |repo|
          stale_commits_description << "== #{repo.name} ==\n"
          stale_commits_description << repo.stale_commits
          stale_commits_description << "\n\n"
        end

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

          main_repository.commit_with_description(message, stale_commits_description, lockfile)
          puts message
        end

        @project.dependant_repositories.select { |repo| repo.commits_not_pushed? }.each do |repo|
          puts_repo_heading(repo)

          create_upstream = !repo.upstream_branch_exists?
          unless repo.push(@args, create_upstream: create_upstream)
            puts_error "Failed to push changes of #{repo.name}.  Try pulling the latest changes or resolve conflicts first."
            return false
          end
        end

        puts_repo_heading(main_repository)
        create_upstream = !main_repository.upstream_branch_exists?
        unless main_repository.push(@args, create_upstream: create_upstream)
          puts_error "Failed to push changes of #{main_repository.name}.  Try pulling the latest changes or resolve conflicts first."
        end
      end

      private

      def prompt_confirm
        if @project.main_repository.file_changed?('Gemfile')
          puts_error 'Your Gemfile has uncommitted changes.  Commit them first before pushing.'
          return false
        end

        commits_to_push = false
        upstream_branches_missing = []
        diverged_repos = []
        @project.repositories.each do |repo|
          commits = repo.commits_not_pushed
          puts_repo_heading(repo)

          if repo.upstream_branch_exists?
            if commits.empty?
              puts 'No changes.'
            else
              commits_to_push = true
              diverged_repos << repo if repo.branch != @project.main_repository.branch
              puts commits
            end
          else
            upstream_branches_missing << repo.name
            puts 'Remote branch does not exist yet.'
          end
        end

        if diverged_repos.any?
          puts_prompt("\nThese repositories have changes and have diverged from the main application's branch (#{@project.main_repository.branch})")
          puts_diverged_repos(diverged_repos)
          puts_prompt("\nDo you want to continue? (Y/N)")
          if STDIN.getch.upcase == 'Y'
            puts ''
          else
            return false
          end
        end

        if !upstream_branches_missing.empty?
          puts_prompt("Missing upstream branches (#{upstream_branches_missing.join(', ')}) will be created and changes pushed.")
          puts_prompt('Do you want to continue? (Y/N)')

        elsif commits_to_push
          puts_prompt('Are you sure you want to push these changes? (Y/N)')

        elsif gemfile_lock_stale?
          puts_prompt('Although you don\'t have any commits to push, your Gemfile.lock needs to be rebuilt, committed and pushed.')
          puts_prompt('Do you want to continue? (Y/N)')

        elsif @project.main_repository.file_changed?('Gemfile.lock')
          puts_prompt('Although you don\'t have any commits to push, your Gemfile.lock needs to be committed and pushed.')
          puts_prompt('Do you want to continue? (Y/N)')
        else
          return false
        end

        STDIN.getch.upcase == 'Y'
      end

      def gemfile_lock_stale?
        @project.repositories.any? { |repo| repo.stale? }
      end

      def build_gemfile_lock
        Dir.chdir(@project.main_repository.path) do
          execute_live('bundle', 'install', '--quiet')
          return $?.exitstatus == 0
        end
      end
    end
  end
end
