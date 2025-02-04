# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 8 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch("WEB_CONCURRENCY") { 4 }
# 20 pg connections on hobby and dev.
# 2 1X dynos * 2 workers * 4 threads = 16 + 4 sidekiq (-c 4) = 20
# or
# 1 2X dynos * 2 workers * 8 threads = 16 + 4 sidekiq (-c 4) = 20
# 120 pg connections on basic-0
# 1 2X dynos * 4 workers * 8 threads = 32 + 8 sidekiq (-c 8) = 40
# 2 2X dynos * 4 workers * 8 threads = 32 + 8 sidekiq (-c 10) = 74
# 3 2X dynos * 4 workers * 8 threads = 32 + 8 sidekiq (-c 14) = 110

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory. If you use this option
# you need to make sure to reconnect any threads in the `on_worker_boot`
# block.

preload_app!

# The code in the `on_worker_boot` will be called if you are using
# clustered mode by specifying a number of `workers`. After each worker
# process is booted this block will be run, if you are using `preload_app!`
# option you will want to use this block to reconnect to any threads
# or connections that may have been created at application boot, Ruby
# cannot share connections between processes.

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
    config['pool'] = max_threads_count
    ActiveRecord::Base.establish_connection(config)
  end
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

require 'barnes'

before_fork do
  # worker specific setup

  Barnes.start # Must have enabled worker mode for this to block to be called
end
