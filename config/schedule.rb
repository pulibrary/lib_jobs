# frozen_string_literal: true

set :output, '/opt/lib-jobs/shared/tmp/cron_log.log'

# Run at 6:05 am EST or 7:05 EDT (after the 6am staff report is generated)
every 1.day, at: '11:05 am' do
  rake "lib_jobs:generate_staff_report"
end
