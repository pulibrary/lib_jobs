### Testing LC Call Slips on staging

One convenient way to try your changes on
production-like data is to run the process on
staging:

1. Deploy main to staging.
1. SSH into one of the staging boxes and run `cd /opt/lib-jobs/current && bundle exec rake lib_jobs:process_newly_cataloged_records`
1. [Open mailcatcher](../../README.md#staging-mail-catcher).
1. Download one of the CSVs that you'd like to compare.
1. Repeat the above steps, but with your branch deployed to staging.
1. Compare the diff between the two CSVs to see
if it is what you expect.  Note that the order
of rows may change, and this doesn't indicate
a problem.
1. You may also choose to run `bundle exec rake lib_jobs:create_csv_for_selector_comparison`, which
generates a CSV of possible records from OCLC,
excluding ones that are typically filtered out like
juvenile materials (based on the `generally_relevant?` method).  You can use this one to make
sure that your CSV in mailcatcher includes all the
expected rows. It is generally put in the `/tmp/oclc/` directory on staging and production.
