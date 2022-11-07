# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebEvents::LibcalUrl, type: :model do
  before do
    allow(LibJobs).to receive(:config).and_return({
      libcal_cid: 'my_calendar_id',
      libcal_k: 'my_k'
    }.with_indifferent_access)
  end

  context 'when it has the correct configuration' do
    it 'creates a valid libcal ical URL' do
      expected_url = 'https://libcal.princeton.edu/ical_subscribe.php?cid=my_calendar_id&k=my_k'
      expect(described_class.new.to_s).to eq(expected_url)
    end
  end
end
