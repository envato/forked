require 'spec_helper'

RSpec.describe Forked::ProcessManager do
  let(:logger) { Logger.new('/dev/null') }
  subject(:pm) { Forked::ProcessManager.new(logger: logger) }

  after do
    pm.shutdown
  end

  it 'forks and shuts down processes' do
    pm.fork('my_process') do
      loop do
        sleep 1
      end
    end
    pm.shutdown
  end

  it 'restarts processes that crash' do
    pm.fork do
      exit 1
    end
    t = Thread.new { pm.wait_for_shutdown }
    pids_1 = pm.worker_pids
    expect(pids_1.count).to eq 1
    sleep 2
    pids_2 = pm.worker_pids
    expect(pids_2.count).to eq 1
    expect(pids_1).to_not eq pids_2
    t.exit
  end

  it "doesn't restart processes that exit gracefully" do
    pm.fork do
      # working..
      # done
    end
    t = Thread.new { pm.wait_for_shutdown }
    sleep 2
    pids_1 = pm.worker_pids
    expect(pids_1.count).to eq 0
    t.exit
  end

  context 'ExponentialBackoffWithLimit retry strategy' do
    it 'accepts the ExponentialBackoffWithLimit' do
      expect(Forked::RetryStrategies::ExponentialBackoffWithLimit)
        .to receive(:new).with(hash_including(logger: logger)).and_call_original

      pm = Forked::ProcessManager.new(logger: logger)
      pm.fork(retry_strategy: Forked::RetryStrategies::ExponentialBackoffWithLimit) {  }
    end

    it 'accepts the ExponentialBackoffWithLimit with an optional backoff_limit parameter' do
      expect(Forked::RetryStrategies::ExponentialBackoffWithLimit)
        .to receive(:new).with(hash_including(logger: logger, limit: 10)).and_call_original

      pm = Forked::ProcessManager.new(logger: logger)
      pm.fork(retry_strategy: Forked::RetryStrategies::ExponentialBackoffWithLimit, retry_backoff_limit: 10) {  }
    end
  end

  context 'custom retry strategies' do
    let(:custom_retry) do
      Class.new do
        def initialize(logger:, on_error:)
        end

        def run(ready_to_stop, &block)
          block.call
        end

        class << self
          attr_accessor :called
        end
        @called = false
      end
    end

    it 'accepts custom retry strategies' do
      pm = Forked::ProcessManager.new(logger: logger)
      pm.fork(retry_strategy: custom_retry) {  }
    end
  end

  describe Forked::RetryStrategies::Always do
    subject(:always) { described_class.new(logger: logger, on_error: Forked::ProcessManager::ON_ERROR) }

    it 'raises' do
      expect {
        always.run(-> {}) do
          raise 'boo'
        end
      }.to raise_error(StandardError, /boo/)
    end
  end

  describe Forked::RetryStrategies::ExponentialBackoff do
    subject(:exponential_backoff) { described_class.new(logger: logger, on_error: Forked::ProcessManager::ON_ERROR) }

    it 'does not raise an error' do
      expect {
        i = 0
        exponential_backoff.run(-> {}) do
          i += 1
          raise 'boo' unless i > 1
        end
      }.to_not raise_error
    end
  end

  describe Forked::RetryStrategies::ExponentialBackoffWithLimit do
    before do
      def exponential_backoff_with_limit.sleep(seconds); end
    end

    subject(:exponential_backoff_with_limit) { described_class.new(logger: logger, on_error: Forked::ProcessManager::ON_ERROR) }

    it 'does not raise an error if backoff limit is not reached' do
      expect {
        i = 0
        exponential_backoff_with_limit.run(-> {}) do
          i += 1
          raise 'boo' unless i > 1
        end
      }.to_not raise_error
    end

    it 'raises an error if backoff limit is reached' do
      expect {
        i = 0
        exponential_backoff_with_limit.run(-> {}) do
          i += 1
          raise StandardError, 'boo'
        end
      }.to raise_error(StandardError, 'boo')
    end
  end
end
