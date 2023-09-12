module GitBundle
  class BranchConfig
    include GitBundle::Console
    BRANCH_CONFIG_FILE = '.gitb.yml'

    attr_reader :filename

    def initialize(filename = nil)
      @filename = filename || BRANCH_CONFIG_FILE
    end

    def path
      File.join(Dir.pwd, filename)
    end

    def current
      return @current if defined?(@current)
      @current = read
    end

    def remote(repo_name)
      source = current[repo_name]
      if source.include?(' ')
        source.split(' ').first
      else
        nil
      end
    end

    def branch(repo_name)
      source = current[repo_name]
      if source.include?(' ')
        source.split(' ').last
      else
        source
      end
    end

    def read
      File.exist?(path) ? YAML.load_file(path) || {} : nil
    end

    def changed?
      current != read
    end

    def save
      if changed?
        File.open(path, 'w') { |file| file.write(current.to_yaml.lines[1..-1].join) }
        if File.exist?(path)
          puts "\t#{colorize('update', 34, bold: true)}\t#{filename}"
        else
          puts "\t#{colorize('create', 32, bold: true)}\t#{filename}"
        end
      else
        puts "\t#{colorize('identical', 34, bold: true)}\t#{filename}"
      end
    end
  end
end