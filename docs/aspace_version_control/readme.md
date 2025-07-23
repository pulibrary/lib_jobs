This process sends ArchivesSpace records, serialized as EAD, to GitLab once a month.

### Summary
The [get_eads](https://github.com/pulibrary/lib_jobs/blob/main/lib/tasks/lib_jobs.rake) task runs the [get_eads_job](https://github.com/pulibrary/lib_jobs/blob/main/app/models/aspace_svn/get_eads_job.rb
). It is [scheduled](https://github.com/pulibrary/lib_jobs/blob/main/config/schedule.rb) to run on the first day of the month.

### Steps
1. authenticate to GitLab and ASpace
2. create directory structure if it doesn't already exist:
   
   The GitLab directory structure organizes the EAD files into directories named after the holding repository and, in the case of Mudd only (for legacy reasons), the holding library. Saving the files into the same structure on download allows the process to commit all files at once.
4. download EADs for all repos
6. add and commit to GitLab

