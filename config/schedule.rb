# frozen_string_literal: true

set :output, '/opt/lib-jobs/shared/tmp/cron_log.log'
env :PATH, ENV["PATH"]

# Run at 6:05 am EST or 7:05 EDT (after the 6am staff report is generated)
every 1.day, at: '11:05 am' do
  rake "lib_jobs:generate_staff_report"
end

# Run in production at 6:15 am EST or 7:15 EDT (after the 6am staff report is generated)
every 1.day, at: '11:15 am', roles: [:alma_cron] do
  rake "lib_jobs:alma_daily_people_feed"
end

# Run in production at 6:25 am EST or 7:25 EDT (after the 6am staff report is generated)
every 1.day, at: '11:25 am', roles: [:alma_cron] do
  rake "lib_jobs:alma_fund_adjustment"
end

# Run in production at 6:35 am EST or 7:35 EDT (after the 6am staff report is generated)
every 1.day, at: '11:35 am', roles: [:alma_cron] do
  rake "lib_jobs:alma_invoice_status_updates"
end
