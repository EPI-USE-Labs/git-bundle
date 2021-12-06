require 'io/console'

module GitBundle
  module Shell
    def execute_pipe(*args)
      puts args.map { |arg| "'#{arg}'" }.join(' ') if ENV['DEBUG'] == 'true'

      pipe_out, pipe_in = IO.pipe
      fork do
        system *args, out: pipe_in, err: pipe_in
      end
      pipe_in.close
      pipe_out
    end

    def execute_live(*args)
      execute_pipe(*args).each_line { |line| puts line.chomp }
    end

    def execute(*args, silence_err: false)
      puts args.map { |arg| "'#{arg}'" }.join(' ') if ENV['DEBUG'] == 'true'

      pipe_out, pipe_in = IO.pipe
      pipe_err_in = silence_err ? File::NULL : pipe_in
      system *args, out: pipe_in, err: pipe_err_in
      pipe_in.close
      pipe_out.read
    end
  end
end