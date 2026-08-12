# frozen_string_literal: true

# This class is responsible for converting an event in the ical
# format to a CSV row
class WebEvents::CSVRowFromIcal
  def call(ical_event)
    [
      ical_event.uid.to_s, # guid column
      ical_event.summary.to_s, # title column
      ical_event.description.to_s,
      ical_event.location.to_s,
      ical_event.dtstart.to_s, # start time column
      ical_event.dtend.to_s, # end time column
      ical_event.url.to_s,
      ical_event.categories.flatten.map(&:strip).join("\t") # categories column
    ]
  end
end
