require 'logger'
require 'timeout'

module Forked
  class ProcessManager
    ON_ERROR = -> (e, tries) { }

    def initialize(process_timeout: 5, logger: Logger.new(STDOUT))
      @process_timeout = process_timeout
      @workers = {}
      @logger = logger
    end

    def fork(name = nil, retry_strategy: ::Forked::RetryStrategies::ExponentialBackoff, retry_backoff_limit: nil, on_error: ON_ERROR, &block)
      worker = Worker.new(
        name: name,
        retry_strategy: retry_strategy,
        retry_backoff_limit: retry_backoff_limit,
        on_error: on_error,
        block: block,
      )
      fork_worker(worker)
    end

    def wait_for_shutdown
      trap_shutdown_signals
      handle_child_processes
      shutdown
    end

    def shutdown
      @logger.info "Master shutting down"
      send_signal_to_workers(:TERM)
      wait_for_workers_until_timeout
      send_signal_to_workers(:KILL)
      @logger.info "Master shutdown complete"
    end

    def worker_pids
      @workers.keys
    end

    private

    def fork_worker(worker)
      retry_params = { logger: @logger, on_error: worker.on_error }
      retry_params[:limit] = worker.retry_backoff_limit if worker.retry_strategy == RetryStrategies::ExponentialBackoffWithLimit
      retry_strategy = worker.retry_strategy.new(**retry_params)

      pid = Kernel.fork do
        WithGracefulShutdown.run(logger: @logger) do |ready_to_stop|
          retry_strategy.run(ready_to_stop) do
            if worker.block.arity > 0
              worker.block.call(ready_to_stop)
            else
              worker.block.call
            end
          end
        end
      end
      @workers[pid] = worker
    end

    def handle_child_processes
      until @shutdown_requested
        # Returns nil immediately if no child process exists
        pid, status = Process.wait2(-1, Process::WNOHANG)
        if pid
          handle_child_exit(pid, status)
        end
        sleep(0.5)
      end
    end

    def handle_child_exit(pid, status)
      worker = @workers.delete(pid)
      identifier = worker&.name || pid

      if status.exited?
        @logger.info "#{identifier} exited with status #{status.exitstatus.inspect}"
      elsif status.coredump?
        @logger.error "#{identifier} exited with a coredump"
      else
        signame = if status.termsig.nil?
                    'no uncaught signal'
                  else
                    Signal.signame(status.termsig)
                  end
        @logger.error "#{identifier} terminated with #{signame}"
      end
      if status.exitstatus.nil? || status.exitstatus.nonzero?
        @logger.error "Restarting #{worker.name || pid}"
        fork_worker(worker)
      end
    end

    def trap_shutdown_signals
      %i(TERM INT).each do |signal|
        Signal.trap(signal) do
          start_shutdown
        end
      end
    end

    def start_shutdown
      @shutdown_requested = true
    end

    def wait_for_workers_until_timeout
      @waiting_since = Time.now
      until @workers.empty? || timed_out?(@waiting_since)
        # Returns nil immediately if no child process exists
        pid, status = Process.wait2(-1, Process::WNOHANG)
        @workers.delete(pid) if pid
      end
    end

    def send_signal_to_workers(signal)
      if !@workers.empty?
        @logger.info "Sending #{signal} to #{@workers.keys}"
        @workers.each_key do |pid|
          begin
            Process.kill(signal, pid)
          rescue Errno::ESRCH => e
            # Errno::ESRCH: No such process
            # Move along if the process is already dead
            @workers.delete(pid)
          end
        end
      end
    end

    def timed_out?(waiting_since)
      Time.now > (waiting_since + @process_timeout)
    end
  end
end
