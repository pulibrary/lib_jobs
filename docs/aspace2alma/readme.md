This workflow loads select collection-level archival records from ArchivesSpace to Alma. It runs daily.

```mermaid
sequenceDiagram
accTitle: Diagram depicting loading select records from ArchivesSpace to Alma.
accDescr {
  Alma Analytics sends barcode report at 1am daily
  aspace2alma requests MARC-XML for all collection-level ASpace records at 4am daily.
  Lib Jobs applies Special Collections changes to default MARC-XML export and adds select records to a single <marc:collection> wrapper.
  Lib Jobs sends MARC-XML file to lib-sftp.
  ASpace to Alma imports profile loads MARC-XML file at 8am daily.
}
Alma->>lib-sftp: Alma Analytics sends barcode report at 1am daily
Lib Jobs->>ASpace: aspace2alma requests MARC-XML for all collection-level ASpace records at 4am daily
loop each Item
  Lib Jobs->>+Lib Jobs: applies Special Collections changes to default MARC-XML export
  Lib Jobs->>+Lib Jobs: adds select records to a single <marc:collection> wrapper
end
Lib Jobs->>lib-sftp: sends MARC-XML file to lib-sftp
Alma->>lib-sftp: ASpace to Alma import profile loads MARC-XML file at 8am daily
```

### Key
[whenever job](https://github.com/pulibrary/aspace_helpers/blob/main/config/schedule.rb)

Alma import profile: Resources > Manage Import Profiles > ASpace to Alma
