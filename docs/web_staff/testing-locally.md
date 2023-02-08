# Testing the staff directory locally

## Running the rake task

If you need to generate the CSV output locally:

1. Download the HR report locally and rename it to something more manageable:
    ````
    scp deploy@lib-jobs-prod1:/mnt/dms-smbserve/bi-library-hr/prod/Department\\\ Absence\\\ Manager\\\ Report\\\ -\\\ Library-en.csv tmp/hr-report.csv
    ````
1. Download yesterday's output and put it in the rails tmp directory.  This is necessary because this job creates a diff between today's list and yesterday's list
    ````
    scp deploy@lib-jobs-prod1:/opt/lib-jobs/shared/staff-directory_[YESTERDAY].csv tmp/
    ````
1. If you have run the rake task previously today, `rm tmp/staff-directory_[TODAY].csv`.  This rake task doesn't run if there's already a data set entry for today and the file is in place. 
1. `HR_STAFF_REPORT_LOCATION=tmp/hr-report.csv bundle exec rake lib_jobs:generate_staff_report`
1. Wait a while, the report can take some time to process.
1. Review your output at `tmp/staff-directory_[TODAY].csv`.

## Importing the output into drupal locally

1. Set up your pul_library_drupal environment locally.
1. Copy the rake task's CSV output from the Rails tmp directory to [pul_library_drupal_repo_path]/sites/default/files/feeds/LibraryDirectoryPrimary.csv
1. In your browser, go to http://library-main.lndo.site/import/pul_library_staff_importer
1. Press the import button.
1. Open the "Logs" tab.  You should see entries that say something like `Imported in 1 seconds` or `There are no new users` or `Created 1 new user`.
1. If the logs contain errors, check the CSV to see if it contains some problematic data.
