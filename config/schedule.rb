# frozen_string_literal: true

set :output, '/opt/lib-jobs/shared/tmp/cron_log.log'
env :PATH, ENV["PATH"]

# Run at 9:05 am EST or 10:05 EDT (after the 6am staff report is generated)
every 1.day, at: '02:05 pm', roles: [:cron_prod2] do
  rake "lib_jobs:generate_staff_report"
end

# Run on production at 7:00 am EST or 8:00 am EDT
every 1.day, at: '12:00 pm', roles: [:cron_prod2] do
  rake "lib_jobs:alma_fund_adjustment"
end

# Run on production at 7:45 pm EST or 8:45 pm EDT (after the daily report is generated at 7:30 pm)
every 1.day, at: '12:45 am', roles: [:cron_prod2] do
  rake "lib_jobs:alma_daily_people_feed"
end

# Run on production at 2:00 am EST or 3:00 am EDT
every 1.day, at: '7:00 am', roles: [:cron_prod2] do
  rake " lib_jobs:voucher_feed"
end

# Run on production at 9:30 pm EST or 10:30 pm EDT
every 1.day, at: '2:30 am', roles: [:cron_prod2] do
  rake " lib_jobs:alma_invoice_status_updates"
end

# Run on production and staging at 10:30 pm EST or 11:30 pm EDT
every 1.day, at: '3:30 am', roles: [:cron_prod2] do
  rake " lib_jobs:clear_out_temp_directories"
end

# Run on production at 6:30 am EST or 7:30 am EDT (after the records are published at 12 am - adding more padding per Mark.)
every 1.day, at: '11:30 am', roles: [:cron_prod2] do # The server is in UTC, so this refers to 11:30 UTC
  rake " lib_jobs:send_pod_records"
end

# Run on production at 8am EST or 9am EDT (after the records are published at 6am)
every 1.day, at: '1:00 pm', roles: [:cron_prod2] do # The server is in UTC, so this is 13:00 UTC
  rake " lib_jobs:renew_alma_requests"
end

# Run on production at 6am EST or 7am EDT
every :monday, at: '11:00 am', roles: [:cron_prod2] do
  rake "lib_jobs:process_newly_cataloged_records"
end

# Run on production Tuesday at 9:30am EST or 10:30am EDT (after the records are published on Sunday)
every :tuesday, at: '2:30 pm', roles: [:cron_prod2] do # The server is in UTC, so this is 14:30 UTC
  rake "lib_jobs:process_bursar_fines"
end

# Run on production Tuesday at 10:30am EST or 11:30am EDT (after the Alma report is scheduled to run)
every :tuesday, at: '3:30 pm', roles: [:cron_prod2] do
  rake "lib_jobs:gobi_isbn_update"
end

# Run on production Wednesday at 7:00am EST or 8:00am EDT
# After Alma submits data to OCLC every Tuesday at 7:00 pm Eastern
every :wednesday, at: '12:00 pm', roles: [:cron_prod2] do
  rake "lib_jobs:process_data_sync_exceptions"
end

# Run on production Wednesday at 7:30am EST or 8:30am EDT
# After Alma submits data to OCLC every Tuesday at 7:00 pm Eastern
every :wednesday, at: '12:30 pm', roles: [:cron_prod2] do
  rake "lib_jobs:process_data_sync_processed"
end

# Run on production Thursday at 9:30am EST or 10:30am EDT (after the records are published on Sunday)
every :thursday, at: '2:30 pm', roles: [:cron_prod2] do # The server is in UTC, so this is 15:30 UTC
  rake "lib_jobs:process_bursar_credits"
end

# Run every hour on the :45 (e.g. 1:45, 2:45, 3:45...)
every '45 * * * *', roles: [:cron_prod2] do
  rake "lib_jobs:generate_events_csv"
end

# Run every day at 12pm and 6pm UTC, 7am and 1pm EST, and 8am and 2pm EDT
every 1.day, at: ['12:00 pm', '6:00 pm'], roles: [:cron_prod2] do
  rake "lib_jobs:generate_database_list_csv"
end

# Run daily at 9pm UTC
every 1.month, at: ['9:00 pm'], roles: [:cron_prod2] do
  rake "lib_jobs:send_eads"
end

# Run every month at 10pm UTC
every :month, at: '10:00 pm', roles: [:cron_prod2] do
  rake "lib_jobs:pull_and_send_agents"
end

# Run every day except Saturday (the aspace maintenance window) at 10:30am UTC (6:30 EDT / 5:30 EST)
every '30 10 * * 0-5', roles: [:cron_prod2] do
  rake "lib_jobs:aspace2alma"
end

# Run on production every Thursday at 3am EST or 4am EDT
# every :thursday, at: '8:00 am', roles: [:cron_prod2] do # The server is in UTC, so that is 8:00 UTC
#   rake "lib_jobs:alma_bib_norm"
# end

# Run on production every day at 7:00am EST or 8:00am EDT
every 1.day, at: '12:00 pm', roles: [:cron_prod2] do
  rake "lib_jobs:process_submit_collection"
end
