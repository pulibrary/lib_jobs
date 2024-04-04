This process sends ArchivesSpace records, serialized as EAD, to SVN once a month.

### Summary
The [get_eads](https://github.com/pulibrary/lib_jobs/blob/main/lib/tasks/lib_jobs.rake) task runs the [get_eads_job](https://github.com/pulibrary/lib_jobs/blob/main/app/models/aspace_svn/get_eads_job.rb
). It is [scheduled](https://github.com/pulibrary/lib_jobs/blob/main/config/schedule.rb) to run on the first Saturday of the month.

### Steps
1. authenticate to SVN and ASpace
2. create directory structure if it doesn't already exist
3. download EADs for all repos
4. update SVN
5. add and commit to SVN

