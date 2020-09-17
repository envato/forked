module Forked
  module RetryStrategies
    class ExponentialBackoffWithLimit
      def initialize(logger:, on_error:, backoff_factor: 2, limit: 8)
        @logger = logger
        @on_error = on_error
        @backoff_factor = backoff_factor
        @limit = 8
      end

      def run(ready_to_stop, &block)
        tries = 0
        begin
          block.call
        rescue => e
          tries += 1

          @logger.error("#{e.class} #{e.message}")
          @on_error.call(e, tries)
          raise if tries > @limit

          sleep_seconds = @backoff_factor**tries
          sleep_seconds.times do
            ready_to_stop.call
            sleep 1
          end

          retry
        end
      end
    end
  end
end
