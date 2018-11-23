# Forked

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

process_manager.fork('monitor', on_error: ->(e, tries) { puts e.inspect }) do
  loop do
    puts "hi"
    sleep 1
  end
end

process_manager.fork('processor_1', retry_strategy: Forked::RetryStrategies::ExponentialBackoff) do |ready_to_stop|
  loop do
    ready_to_stop.call # triggers a shutdown if a TERM/INT signal has been received
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
