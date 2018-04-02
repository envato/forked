RSpec.describe Forked::RetryStrategies::Always do
  let(:ready_to_stop) { ->{} }
  let(:logger) { instance_double(Logger, error: nil) }
  let(:on_error) { instance_double(Proc, call: nil) }
  subject(:always) { described_class.new(logger: logger, on_error: on_error) }

  it 'returns the result of the block' do
    return_value = always.run(->{}) { 42 }
    expect(return_value).to eq 42
  end

  it "doesn't swallow errors" do
    expect {
      always.run(ready_to_stop) { raise StandardError, 'boo' }
    }.to raise_error StandardError
  end

  it 'calls on_error on error' do
    always.run(->{}) { raise TestError } rescue TestError
    expect(on_error).to have_received(:call).with(an_instance_of(TestError), 1)
  end

  it 'logs the error' do
    always.run(->{}) { raise TestError } rescue TestError
    expect(logger).to have_received(:error)
  end
end
