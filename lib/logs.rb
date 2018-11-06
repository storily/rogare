# frozen_string_literal: true

def logs(msg)
  puts msg
  STDOUT.flush
end

$stdout.sync = true unless ENV['RACK_ENV'] == 'production'
