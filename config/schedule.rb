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
