# frozen_string_literal: true
module TMASGateCounts
  Slice.register_provider(:wait_for_rate_limit) do
    start do
      # The TMAS client needs to wait for 2 seconds between each request --
      # this provider provides the needed pause
      register('tmas_client.wait_for_rate_limit', memoize: true) { ->() { sleep 2 } }
    end
  end
end
