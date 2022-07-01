# Testing on Staging
In Gerneral it is hard if not impossible to test these processes end to end before putting them unto production.  
You can do some testing on staging for the parts that run within the staging environment.  
For example make sure that files get cretaed in the samba share as expected of that files get put onto the FTP server.
Unfotunately when the system interacts with an API instead of a file based transfer this can, like the NCIP renewal, this can be almost impossible to test from staging. 

## Finding test Input data

Most of the processes are kicked off by a file showing up either in a samba share or on the FTP server.  
You can rerun any of these files through a rake task on the staging server by removing .processed from the end of the file.

Note that the samba shares, and or the FTP directories that staging processes may not be the same as the as the directories on production.  
You may need to copy data from the production server mount/ ftp directory to the staging server mount/ ftp directory.  
For samba mounted directories you may need to copy from production to your machine and then up to staging.

## Running the job

Either looking at config/schedule.rb or the crontab on production is the easiest way to find out how to run a particular task.  Generally they are rake tasks.

## Verifying the output

All processes create a data set.  You can look at the Ui for the data set that your run has been recorded as expected.

If the output is a file you can also verify that what your are expecting has shown up in the file either on the samba share or on the ftp server.
