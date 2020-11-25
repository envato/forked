module Forked
  class Worker < Struct.new(
    :name,
    :retry_strategy,
    :retry_backoff_limit,
    :on_error,
    :block,
    keyword_init: true)
  end
end
