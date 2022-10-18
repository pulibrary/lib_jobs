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

# Run on production at 10:00 pm EST or 9:00 pm EDT
every 1.day, at: '2:00 am', roles: [:prod] do
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

# Run on production at 7:30 am EST or 6:30 am EDT (after the records are published at 12 am - adding more pdding per Mark.)
every 1.day, at: '11:30 am', roles: [:prod] do # The server is in UTC, so this refers to 11:30 UTC
  rake " lib_jobs:send_pod_records"
end

# Run on production at 9am EST or 8am EDT (after the records are published at 6am)
every 1.day, at: '1:00 pm', roles: [:prod] do # The server is in UTC, so this is 13:00 UTC
  rake " lib_jobs:renew_alma_requests"
end

# Run on production Tuesday at 10:30am EST or 11:30am EDT (after the records are published on Sunday)
every :tuesday, at: '2:30 pm', roles: [:prod] do # The server is in UTC, so this is 14:30 UTC
  rake "lib_jobs:process_bursar_fines"
end

# Run on production Thursday at 10:30am EST or 11:30am EDT (after the records are published on Sunday)
every :thursday, at: '2:30 pm', roles: [:prod] do # The server is in UTC, so this is 15:30 UTC
  rake "lib_jobs:process_bursar_credits"
end
