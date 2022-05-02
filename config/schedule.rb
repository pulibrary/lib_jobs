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
every 1.day, at: '12:45 pm', roles: [:prod] do
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

# Run on production at 2:30 am EST or 1:30 am EDT (after the records are published at 12 am)
every 1.day, at: '6:30 am', roles: [:prod] do # The server is in UTC, so this is 6:30 UTC
  rake " lib_jobs:send_pod_records"
end

# Run on production at 4am EST or 3am EDT (after the records are published at 2am)
every 1.day, at: '8:00 am', roles: [:prod] do # The server is in UTC, so this is 8:00 UTC
  rake " lib_jobs:renew_alma_requests"
end
