# frozen_string_literal: true
require 'uri'

module WebEvents
  Slice.register_provider(:libcal_url) do
    start do
      url = "https://libcal.princeton.edu/ical_subscribe.php?cid=#{target['settings'].libcal_cid}&k=#{target['settings'].libcal_k}"
      register 'libcal_url', URI(url)
    end
  end
end
