This workflow loads select collection-level, as well as remote-storage item-level, archival records from ArchivesSpace to Alma. It runs daily.

### Steps and Contingencies

This workflow relies on a barcode report via Alma Analytics, which makes the correct timing of the steps a critical piece of this integration.
1. Alma prepares a data snapshot at 8pm each night; it becomes available to Analytics around midnight.
2. At 1am, Alma reports out all item barcodes associated with archivally managed items (location codes starting with "sca"). It exports the report to lib-sftp-prod1.
3. At 2:30am, aspace2alma starts processing on lib-jobs-prod2:
    1. it retrieves the barcodes report from lib-sftp-prod1
        1. once downloaded, it renames the file
        2. if it finds no current file, the process exits
    1. it retrieves collection-level records from ArchivesSpace
    1. for each top_container record, it checks these 3 things and, if true, creates a MARC item record:
        1. it has a barcode
        1. it has a ReCAP location
        1. it does not match any item on the Alma barcode report
    1. when finished, aspace2alma goes to lib-sftp-prod1 and
        1. renames the previous output file
        2. saves the current output file
  4. At 9:00am, Alma goes to lib-sftp-prod1:
     1. if it finds the current output file (by filename), it imports the records
     1. if it doesn't find the current output file, nothing gets imported

### Overview


```mermaid
sequenceDiagram
accTitle: Diagram depicting loading select records from ArchivesSpace to Alma.
accDescr {
  Alma Analytics sends barcode report at 1am daily.
  aspace2alma requests barcode report at 2:30am daily; deletes report once downloaded.
  aspace2alma requests MARC-XML for all collection-level ASpace records at 2:30am daily.
  Lib Jobs applies Special Collections changes to default MARC-XML export and adds select records to a single <marc:collection> wrapper.
  Lib Jobs gets top_container records from ASpace.
  Lib Jobs constructs item records from top_container records that 1.are at ReCAP 2. have a barcode 3.are not on the Alma barcode report.
  Lib Jobs sends MARC-XML file to lib-sftp; renames old file.
  ASpace to Alma imports profile loads MARC-XML file at 9am daily.
}
Alma->>lib-sftp: Alma Analytics sends barcode report at 1am daily
Lib Jobs->>lib-sftp: aspace2alma requests barcode report at 2:30am daily, deletes report once downloaded
Lib Jobs->>ASpace: aspace2alma requests MARC-XML for all collection-level ASpace records at 2:30am daily
loop each Item
  Lib Jobs->>+Lib Jobs: applies Special Collections changes to default MARC-XML export
  Lib Jobs->>+Lib Jobs: gets top_container records from ASpace
  Lib Jobs->>+Lib Jobs: constructs item records from top_container records that 1.are at ReCAP 2. have a barcode 3.are not on the Alma barcode report
  Lib Jobs->>+Lib Jobs: adds select records to a single <marc:collection> wrapper
end
Lib Jobs->>lib-sftp: sends MARC-XML file to lib-sftp, renames old file
Alma->>lib-sftp: ASpace to Alma import profile loads MARC-XML file at 9am daily
```

### Key
[whenever job](https://github.com/pulibrary/aspace_helpers/blob/main/config/schedule.rb)

Alma import profile: Resources > Manage Import Profiles > ASpace to Alma
