This workflow loads select collection-level archival records from ArchivesSpace to Alma. It runs daily.

```mermaid
sequenceDiagram
Lib Jobs->>ASpace: aspace2alma requests MARC-XML for all collection-level ASpace records at 4am daily
loop each Item
  Lib Jobs->>+Lib Jobs: applies Special Collections changes to default MARC-XML export
  Lib Jobs->>+Lib Jobs: adds select records to a single <marc:collection> wrapper
end
Lib Jobs->>lib-sftp: sends MARC-XML file to lib-sftp
Alma->>lib-sftp: ASpace to Alma import profile loads MARC-XML file at 8am daily
```
