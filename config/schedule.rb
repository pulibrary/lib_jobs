# frozen_string_literal: true

set :output, '/opt/lib-jobs/shared/tmp/cron_log.log'
env :PATH, ENV["PATH"]

# Run at 6:05 am EST or 7:05 EDT (after the 6am staff report is generated)
every 1.day, at: '11:05 am' do
  rake "lib_jobs:generate_staff_report"
end

# Run on production at 8:00 pm EST or 7:00 pm EDT
every 1.day, at: '12:00 pm', roles: [:prod] do
  rake "lib_jobs:alma_fund_adjustment"
end

# Run on production at 8:45 pm EST or 7:45 pm EDT (after the daily report is generated at 7:30 pm)
every 1.day, at: '12:45 am', roles: [:prod] do
  rake "lib_jobs:alma_daily_people_feed"
end

# Run on production at 3:00 am EST or 2:00 am EDT
every 1.day, at: '7:00 am', roles: [:prod] do
  rake " lib_jobs:voucher_feed"
end

# Run on production at 10:30 pm EST or 9:30 pm EDT
every 1.day, at: '2:30 am', roles: [:prod] do
  rake " lib_jobs:alma_invoice_status_updates"
end

# Run on production and staging at 11:30 pm EST or 10:30 pm EDT
every 1.day, at: '3:30 am', roles: [:app] do
  rake " lib_jobs:clear_out_temp_directories"
end

# Run on production at 7:30 am EST or 6:30 am EDT (after the records are published at 12 am - adding more padding per Mark.)
every 1.day, at: '11:30 am', roles: [:prod] do # The server is in UTC, so this refers to 11:30 UTC
  rake " lib_jobs:send_pod_records"
end

# Run on production at 9am EST or 8am EDT (after the records are published at 6am)
every 1.day, at: '1:00 pm', roles: [:prod] do # The server is in UTC, so this is 13:00 UTC
  rake " lib_jobs:renew_alma_requests"
end

# Run on production at 7am EST or 6am EDT
every :monday, at: '11:00 am', roles: [:prod] do
  rake "lib_jobs:process_newly_cataloged_records"
end

# Run on production Tuesday at 10:30am EST or 11:30am EDT (after the records are published on Sunday)
every :tuesday, at: '2:30 pm', roles: [:prod] do # The server is in UTC, so this is 14:30 UTC
  rake "lib_jobs:process_bursar_fines"
end

# Run on production Wednesday at 10:00am EST or 11:00am EDT
# After Alma submits data to OCLC every Tuesday at 7:00 pm Eastern
every :wednesday, at: '12:00 pm', roles: [:prod] do
  rake "lib_jobs:process_data_sync_exceptions"
end

# Run on production Wednesday at 10:30am EST or 11:30am EDT
# After Alma submits data to OCLC every Tuesday at 7:00 pm Eastern
every :wednesday, at: '12:30 pm', roles: [:prod] do
  rake "lib_jobs:process_data_sync_processed"
end

# Run on production Thursday at 10:30am EST or 11:30am EDT (after the records are published on Sunday)
every :thursday, at: '2:30 pm', roles: [:prod] do # The server is in UTC, so this is 15:30 UTC
  rake "lib_jobs:process_bursar_credits"
end

# Run every hour on the :45 (e.g. 1:45, 2:45, 3:45...)
every '45 * * * *' do
  rake "lib_jobs:generate_events_csv"
end

# Run every day at 12pm and 6pm
every 1.day, at: ['12:00 pm', '6:00 pm'], roles: [:prod] do
  rake " lib_jobs:generate_database_list_csv"
end

# Run once a month
every '0 6 1 * *', roles: [:prod] do
  rake " lib_jobs:send_eads"
end

# Run on production every Thursday at 4am EST or 5am EDT
every :thursday, at: '8:00 am', roles: [:prod] do # The server is in UTC, so that is 8:00 UTC
  rake "lib_jobs:alma_bib_norm"
end

# Run on production every day at 8:00am EST or 9:00am EDT
every 1.day, at: '12:00 pm', roles: [:prod] do
  rake "lib_jobs:process_submit_collection"
end
