module Infuser
  class Logger

    def info msg
      output msg
    end

    def warn msg
      output "WARN: #{msg}"
    end

    def error msg
      output "ERROR: #{msg}"
    end

    def debug msg
      output msg
    end

    def fatal
      output "FATAL: #{msg}"
    end


    private

    def output data
      $stdout.puts data
    end

  end
end
