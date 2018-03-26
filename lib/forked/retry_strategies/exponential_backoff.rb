module Forked
  module RetryStrategies
    class ExponentialBackoff
      def initialize(logger:, on_error:, backoff_factor: 2)
        @logger = logger
        @on_error = on_error
        @backoff_factor = backoff_factor
      end

      def run(ready_to_stop, &block)
        tries = 0
        begin
          block.call
        rescue => e
          tries += 1
          sleep_seconds = @backoff_factor**tries
          @logger.error("#{e.class} #{e.message}")
          @on_error.call(e, tries)
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
