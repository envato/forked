RSpec.describe Forked::RetryStrategies::ExponentialBackoffWithLimit do
  let(:ready_to_stop) { ->{} }
  let(:logger) { instance_double(Logger, error: nil) }
  let(:on_error) { instance_double(Proc, call: nil) }
  let(:raise_error_on_first_try_block) do
    tries = 0
    proc do
      if tries == 0
        tries += 1
        raise TestError
      end
      tries += 1
      tries
    end
  end
  subject(:exponential_backoff_with_limit) { described_class.new(logger: logger, on_error: on_error) }

  before do
    def exponential_backoff_with_limit.sleep(seconds); end
  end

  it 'returns the result of the block' do
    return_value = exponential_backoff_with_limit.run(ready_to_stop) { 42 }
    expect(return_value).to eq 42
  end

  it 'calls on_error on error then returns' do
    return_value = exponential_backoff_with_limit.run(->{}) do
      raise_error_on_first_try_block.call
      42
    end
    expect(on_error).to have_received(:call).with(an_instance_of(TestError), 1)
    expect(return_value).to eq 42
  end

  it 'logs the error' do
    exponential_backoff_with_limit.run(->{}) { raise_error_on_first_try_block.call } rescue TestError
    expect(logger).to have_received(:error)
  end

  it 'calls ready to stop each second interval' do
    ready_to_stop = instance_double(Proc, call: nil)
    exponential_backoff_with_limit.run(ready_to_stop) { raise_error_on_first_try_block.call }
    expect(ready_to_stop).to have_received(:call).twice
  end

  it 'sleeps with exponential backoff' do
    tries = 1
    raise_twice_block = proc do
      if tries < 3
        tries += 1
        raise TestError
      end
      tries += 1
      tries
    end

    # 2 seconds first error, 4 seconds second error = sleep called 6 times
    expect(exponential_backoff_with_limit).to receive(:sleep).with(1).exactly(6).times

    exponential_backoff_with_limit.run(ready_to_stop) { raise_twice_block.call }
  end

  it 'limits the number of tries' do
    start = 1
    raise_10_times_block = proc do
      (start..10).each do |position|
        start = (position + 1) # starting position next time the block is called
        raise TestError
      end
    end

    # Loops 1-8: errors, 2**try seconds for each try
    #   Back off for 2+4+8+16+32+64+128+256 seconds = sleep is called 510 times
    # The 9th and 10th loop through the block is never called
    # because the retries are limited by default to 8
    expect(exponential_backoff_with_limit).to receive(:sleep).with(1).exactly(510).times

    expect {
      exponential_backoff_with_limit.run(ready_to_stop) { raise_10_times_block.call }
    }.to raise_error TestError
  end
end
