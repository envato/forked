module Forked
  class Worker < Struct.new(:name, :retry_strategy, :on_error, :block)
  end
end
