# frozen_string_literal: true
class WebEvents::LibcalUrl
  def initialize
    @cid = LibJobs.config[:libcal_cid]
    @k = LibJobs.config[:libcal_k]
  end

  def to_s
    "https://libcal.princeton.edu/ical_subscribe.php?cid=#{@cid}&k=#{@k}"
  end
end
