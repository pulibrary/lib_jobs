This workflow loads select collection-level, as well as remote-storage item-level, archival records from ArchivesSpace to Alma. It runs daily.

### Schedule and Considerations

The workflow relies on a barcode report via Alma Analytics, which makes the correct timing of the steps a critical piece of this integration.

The steps include a report scheduled in Alma Analytics as well as [two cron jobs scheduled in aspace_helpers](https://github.com/pulibrary/aspace_helpers/blob/main/config/schedule.rb).

The first cron job runs aspace2alma every morning except Mondays, when Alma jobs tend to be backed up, which runs the risk of dealying the Alma Analytics barcodes report, and Saturdays, when ASpace goes down for maintenance.

The second cron job runs on days when we skip aspace2alma (i.e. Mondays and Saturdays) to delete the prior day's `MARC_out.xml` file. (Since aspace2alma doesn't run on those days, the file doesn't get deleted/renamed on those days, making it available for import to the Alma import job a second time. This is not allowed to happen because it might import item records a second time, which Alma permits, creating duplicate item records.)

The following shows the schedules of the interdependent steps in both UTC and EST/EDT:

| service | server | server clock | scheduled literally as | EDT (summer) (=UTC-4) | EST (winter) (=UTC-5) | UTC (summer)(=EDT+4) | UTC (winter) (=EST+5)| duration (appr.) |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| Alma Analytics | Alma | Eastern | 3:00am | 3:00am | 3:00am | 7:00am | 9:00am | 30 mins | 
| aspace2alma | lib-jobs | UTC | 10:30am | 6:30am | 5:30am | 10:30am | 11:30am | 2 hrs 30 mins | 
| Alma Import Job | Alma | Eastern | 11:00am | 11:00am | 11:00am | 3:00pm | 4:00pm | 5 mins |


### Steps

1. Alma internally) prepares a data snapshot at 8pm each night that becomes available to Analytics around midnight (winter) / 1am (summer).
  
(Alma jobs are scheduled in the user's current time zone. We can surmise that the Analytics server is scheduled in UTC behind the scenes.)

2. Alma Analytics (via a scheduled job) reports out all item barcodes associated with archivally managed items (location codes starting with "sca"). It exports the report to `lib-sftp-prod1`.
3. Subsequently, `aspace2alma` starts processing on `lib-jobs-prod2`:
    1. it removes `MARC_out_old.xml`
    2. it renames `MARC_out.xml` to `MARC_out_old.xml` (so that in case the export fails, Alma will not find a stale `MARC_out.xml` file to import)
    3. it retrieves the Analytics barcodes report from `lib-sftp-prod1`
        1. once the barcodes report is downloaded,
            1. it removes `sc_active_barcodes_old.csv`
            2. it renames `sc_active_barcodes.csv` to `sc_active_barcodes_old.csv` (to prevent the process from running if
  either the fresh report from Alma does not arrive or the ASpace export fails)
        2. if it finds no current `sc_active_barcodes.csv` file on lib-sftp, the process exits
    1. it retrieves collection-level records from ArchivesSpace
    1. for each top_container record, it checks these 3 things and, if true, creates a MARC item record:
        1. it has a barcode
        1. it has a ReCAP location
        1. it does not match any item on the Alma barcode report (loaded into a variable as an array)
    1. when finished, `aspace2alma` saves the current `MARC_out.xml` to `lib-sftp-prod1`
  6. Finally, Alma goes to `lib-sftp-prod1`:
     1. if it finds the current MARC file (`MARC_out.xml`), it imports the records
     1. if it doesn't find the current MARC file, nothing gets imported

### Overview

```mermaid
sequenceDiagram
accTitle: Diagram depicting loading select records from ArchivesSpace to Alma.
accDescr {
  Alma Analytics sends barcode report at 1am daily.
  aspace2alma renames old MARC-XML file on lib-sftp-prod1.
  aspace2alma requests barcode report at 2:30am daily; renames report once downloaded.
  aspace2alma requests MARC-XML for all collection-level ASpace records at 2:30am daily.
  Lib Jobs applies Special Collections changes to default MARC-XML export and adds select records to a single <marc:collection> wrapper.
  Lib Jobs gets top_container records from ASpace.
  Lib Jobs constructs item records from top_container records that 1.are at ReCAP 2. have a barcode 3.are not on the Alma barcode report.
  Lib Jobs sends MARC-XML file to lib-sftp.
  ASpace to Alma imports profile loads MARC-XML file at 9am daily.
}
Alma->>lib-sftp: Alma Analytics sends barcode report at 1am daily
Lib Jobs->>lib-sftp: aspace2alma renames old MARC-XML file on lib-sftp-prod1
Lib Jobs->>lib-sftp: aspace2alma requests barcode report at 2:30am daily, renames report once downloaded; lib-jobs makes the barcode report available
Lib Jobs->>ASpace: aspace2alma requests MARC-XML for all collection-level ASpace records at 2:30am daily
loop each Item
  Lib Jobs->>+Lib Jobs: applies Special Collections changes to default MARC-XML export
  Lib Jobs->>+Lib Jobs: gets top_container records from ASpace
  Lib Jobs->>+Lib Jobs: constructs item records from top_container records that 1.are at ReCAP 2. have a barcode 3.are not on the Alma barcode report as confirmed via API call to lib-jobs
  Lib Jobs->>+Lib Jobs: adds select records to a single <marc:collection> wrapper
end
Lib Jobs->>lib-sftp: sends MARC-XML file to lib-sftp
Alma->>lib-sftp: ASpace to Alma import profile loads MARC-XML file at 9am daily
```

### Key
[whenever job](https://github.com/pulibrary/aspace_helpers/blob/main/config/schedule.rb)

Alma import profile: Resources > Manage Import Profiles > ASpace to Alma
