# frozen_string_literal: true
module TMASGateCounts
  Slice.register_provider(:princeton_timezone) do
    start do
      register 'princeton_timezone', ActiveSupport::TimeZone.new('Eastern Time (US & Canada)')
    end
  end
end
