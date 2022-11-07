# frozen_string_literal: true
class WebEvents::Event
  def initialize(ical_event)
    @guid = ical_event.uid.to_s
    @title = ical_event.summary.to_s
    @description = ical_event.description.to_s
    @location = ical_event.location.to_s
    @start_time = ical_event.dtstart.to_s
    @end_time = ical_event.dtend.to_s
    @url = ical_event.url.to_s
    @categories = ical_event.categories.flatten.map(&:strip).join("\t")
  end

  def to_a
    [
      @guid,
      @title,
      @description,
      @location,
      @start_time,
      @end_time,
      @url,
      @categories
    ]
  end
end
