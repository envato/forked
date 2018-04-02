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
    let(:on_error) { double(call: true) }
    subject(:always) { described_class.new(logger: logger, on_error: on_error) }

    it 'raises' do
      expect {
        always.run(-> {}) do
          raise 'boo'
        end
      }.to raise_error(StandardError, /boo/)
    end
  end

  describe Forked::RetryStrategies::ExponentialBackoff do
    let(:on_error) { double(call: true) }
    subject(:always) { described_class.new(logger: logger, on_error: on_error) }

    it 'raises' do
      expect {
        i = 0
        always.run(-> {}) do
          i += 1
          raise 'boo' unless i > 1
        end
      }.to_not raise_error
    end
  end
end
