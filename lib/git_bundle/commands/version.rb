module GitBundle
  module Commands
    class Version
      include GitBundle::Console

      def invoke
        puts "git-bundle version #{GitBundle::VERSION}"
        puts "bundler version #{Bundler::VERSION}"
        system 'git', '--version'
      end
    end
  end
end