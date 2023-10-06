This workflow loads select collection-level archival records from ArchivesSpace to Alma. It runs daily.

```mermaid
sequenceDiagram
accTitle: Diagram depicting loading select records from ArchivesSpace to Alma.
accDescr {
  Alma Analytics sends barcode report at 1am daily.
  aspace2alma requests barcode report at 3:30am daily; deletes report once downloaded.
  aspace2alma requests MARC-XML for all collection-level ASpace records at 3:30am daily.
  Lib Jobs applies Special Collections changes to default MARC-XML export and adds select records to a single <marc:collection> wrapper.
  Lib Jobs gets top_container records from ASpace.
  Lib Jobs constructs item records from top_container records that 1.are at ReCAP 2. have a barcode 3.are not on the Alma barcode report.
  Lib Jobs sends MARC-XML file to lib-sftp; renames old file.
  ASpace to Alma imports profile loads MARC-XML file at 8am daily.
}
Alma->>lib-sftp: Alma Analytics sends barcode report at 1am daily
Lib Jobs->>lib-sftp: aspace2alma requests barcode report at 3:30am daily, deletes report once downloaded
Lib Jobs->>ASpace: aspace2alma requests MARC-XML for all collection-level ASpace records at 3:30am daily
loop each Item
  Lib Jobs->>+Lib Jobs: applies Special Collections changes to default MARC-XML export
  Lib Jobs->>+Lib Jobs: gets top_container records from ASpace
  Lib Jobs->>+Lib Jobs: constructs item records from top_container records that 1.are at ReCAP 2. have a barcode 3.are not on the Alma barcode report
  Lib Jobs->>+Lib Jobs: adds select records to a single <marc:collection> wrapper
end
Lib Jobs->>lib-sftp: sends MARC-XML file to lib-sftp, renames old file
Alma->>lib-sftp: ASpace to Alma import profile loads MARC-XML file at 8am daily
```

### Key
[whenever job](https://github.com/pulibrary/aspace_helpers/blob/main/config/schedule.rb)

Alma import profile: Resources > Manage Import Profiles > ASpace to Alma
