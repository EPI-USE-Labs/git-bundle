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

    def read
      File.exists?(path) ? YAML.load_file(path) || {} : nil
    end

    def changed?
      current != read
    end

    def save
      File.open(path, 'w') {|file| file.write(current.to_yaml.lines[1..-1].join)}
      if File.exists?(path)
        puts "\t#{colorize('update', 34, bold: true)}\t#{filename}"
      else
        puts "\t#{colorize('create', 32, bold: true)}\t#{filename}"
      end
    end
  end
end