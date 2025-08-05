This process sends ArchivesSpace records, serialized as EAD, to GitLab once a month.

### Summary
The [get_eads](https://github.com/pulibrary/lib_jobs/blob/main/lib/tasks/lib_jobs.rake) task runs the [get_eads_job](https://github.com/pulibrary/lib_jobs/blob/main/app/models/aspace_version_control/get_eads_job.rb
). It is [scheduled](https://github.com/pulibrary/lib_jobs/blob/main/config/schedule.rb) to run on the first day of the month.

### Steps
1. authenticates to GitLab and ASpace
2. creates directory structure if it doesn't already exist:
   
   The GitLab directory structure organizes the EAD files into directories named after the holding repository and, in the case of Mudd only (for legacy reasons), the holding library. Saving the files into the same structure on download allows the process to commit all files at once.
4. downloads EADs for all repos
6. adds and commits to GitLab

### To Run Manually
1. `ssh deploy@lib-jobs-prod2.princeton.edu` (don't forget VPN)
2. `cd /opt/lib-jobs/current/`
3. `bundle exec rake lib_jobs:send_eads`

