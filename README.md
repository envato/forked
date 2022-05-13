# Forked

[![License MIT](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://github.com/envato/forked/blob/master/LICENSE.txt)
[![Gem Version](https://img.shields.io/gem/v/forked.svg?maxAge=2592000)](https://rubygems.org/gems/forked)
[![Gem Downloads](https://img.shields.io/gem/dt/forked.svg?maxAge=2592000)](https://rubygems.org/gems/forked)
[![Test Suite](https://github.com/envato/forked/workflows/tests/badge.svg?branch=master)](https://github.com/envato/forked/actions?query=branch%3Amaster+workflow%3Atests)

Forked manages long running worker processes.

Processes that crash are restarted, whereas processes that exit successfully
aren't. Errors that occur within forked processes are retried according to the
configured retry strategy.

Once `wait_for_shutdown` is called, the current process watches for shutdown
signals or crashed processes. On shutdown, each worker is sent a TERM signal,
indicating that it should finish any in progress work and shutdown. After a set
timeout period workers are sent a KILL signal.

## Usage

```ruby
require 'forked'

process_manager = Forked::ProcessManager.new(logger: Logger.new(STDOUT), process_timeout: 5)

# Default retry_strategy = Forked::RetryStrategies::Always
# Calling `ready_to_stop` within the loop ensures a shutdown is triggered if a TERM/INT signal is received
process_manager.fork('monitor', on_error: ->(e, tries) { puts e.inspect }) do |ready_to_stop|
  loop do
    ready_to_stop.call
    # do something
  end
end

# Using the ExponentialBackoff retry_strategy
# If there is an error, process_manager backs off for a time then restarts the loop
# The back off time increases as the number of errors increase
process_manager.fork('processor_1', retry_strategy: Forked::RetryStrategies::ExponentialBackoff) do |ready_to_stop|
  loop do
    ready_to_stop.call
    # do something
  end
end

# Using the ExponentialBackoffWithLimit retry_strategy
# Follows the ExponentialBackoff retry strategy, but if the error keeps occurring
#   until a given limit (default: 8), the error bubbles up and the loop is not restarted
process_manager.fork('processor_1', retry_strategy: Forked::RetryStrategies::ExponentialBackoffWithLimit, retry_backoff_limit: 10) do |ready_to_stop|
  loop do
    ready_to_stop.call
    # do something
  end
end

# blocks the current process, restarts any crashed processes and waits for shutdown signals (TERM/INT).
process_manager.wait_for_shutdown
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/envato/forked.
