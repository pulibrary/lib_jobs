# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebEvents::Event, type: :model do
  describe '#to_csv' do
    let(:categories) { ['Workshops', 'Events'] }
    let(:ical_event) do
      calendar = Icalendar::Calendar.new
      calendar.event do |e|
        e.uid         = '1234'
        e.summary     = 'Workshop title'
        e.description = 'an 11-hour workshop'
        e.location    = 'Milberg Gallery, Firestone Library'
        e.dtstart     = DateTime.civil(2025, 6, 23, 7, 0)
        e.dtend       = DateTime.civil(2025, 6, 23, 18, 0)
        e.url         = 'https://princeton.edu/events'
        e.categories  = categories
      end
      calendar.events.first
    end
    let(:csv_row) do
      [
        '1234',
        'Workshop title',
        'an 11-hour workshop',
        'Milberg Gallery, Firestone Library',
        '2025-06-23T07:00:00+00:00',
        '2025-06-23T18:00:00+00:00',
        'https://princeton.edu/events',
        "Workshops\tEvents"
      ]
    end
    it 'converts an Ical event to an array' do
      event = described_class.new(ical_event)
      expect(event.to_a).to eq(csv_row)
    end

    context 'category has extra spaces' do
      let(:categories) { [' Workshops', 'Events '] }

      it 'trims extra space' do
        event = described_class.new(ical_event)
        expect(event.to_a.last).to eq("Workshops\tEvents")
      end
    end
  end
end
