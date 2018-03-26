module Forked
  module RetryStrategies
    # Relies on the master restarting the worker process
    class Always
      def initialize(logger:, on_error:)
        @logger = logger
        @on_error = on_error
      end

      def run(ready_to_stop, &block)
        block.call
      rescue => e
        @logger.error("#{e.class} #{e.message}")
        @on_error.call(e, 1)
        raise
      end
    end
  end
end
