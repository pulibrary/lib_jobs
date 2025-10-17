This workflow loads select collection-level archival records from ArchivesSpace to Alma. It runs daily. The collection-level records include holdings and (for ReCAP items only) item records.

### Schedule and Considerations

The workflow relies on barcode deduplication as well as file management to ensure no barcodes are loaded into Alma twice. 
  - It requests barcodes for all SC holdings from the Alma API
  - It prunes from the MARC XML file to be imported all item records with barcodes that are already present in Alma.
  - It renames the import file on sftp to make sure Alma can only load it once.

Two [cron jobs](lib_jobs/config/schedule.rb) schedule this integration. 
  - The first runs aspace2alma every morning except Saturdays, when ASpace goes down for maintenance.
  - The second runs on Saturdays to delete the prior day's `MARC_out.xml` file. (Since aspace2alma doesn't run on those days, the file doesn't get deleted/renamed on those days, making it available for import to the Alma import job a second time.)

### Steps

1. the [send_marcxml_to_alma_job](https://github.com/pulibrary/lib_jobs/blob/568202359ec99c2fd2586a7d262992a3b095ee35/app/models/aspace2alma/send_marcxml_to_alma_job.rb) starts processing on `lib-jobs-prod2`:
    1. it removes `MARC_out_old.xml` from lib-sftp and renames `MARC_out.xml` to `MARC_out_old.xml` (so that in case the export fails, Alma will not find a stale `MARC_out.xml` file to import)
    2. it gets the resource records from ASpace via the MARC-xml endpoint
    3. it gets the barcodes from Alma
    4. for each top_container record, it checks 3 things and, if true, creates a MARC item record:
        1. it has a barcode
        1. it has a ReCAP location
        1. it does not match any item on the Alma barcode report (loaded into a variable as an array)
    5. when finished, `aspace2alma` saves the current `MARC_out.xml` to `lib-sftp-prod1`
  2. Each morning, Alma goes to `lib-sftp-prod1`:
     1. if it finds the current MARC file (`MARC_out.xml`), it imports the records
     1. if it doesn't find the current MARC file, nothing gets imported

The Alma import profile can be found at: Resources > Manage Import Profiles > ASpace to Alma
