# frozen_string_literal: true
# there is validation based on time, so we either need to change the current time or change the dates in the file
#  pinning the time to a valid time seems easier.
# If tests start to fail with unexpected "Invalid invoice date: must be between four years old and one month into the future" we likely need to pin time in that test too
def pin_time_to_valid_invoice_list
  zone = Time.zone
  allow(Time).to receive(:zone).and_return(zone)
  allow(zone).to receive(:now).and_return(Time.zone.parse('2021-07-01 15:30:45'))
end
