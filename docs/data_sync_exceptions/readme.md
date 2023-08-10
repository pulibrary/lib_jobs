This job downloads BibException reports from OCLC-sftp, creates a Marc Collection with individual records for each MMS ID, and uploads the file with the Marc Collection to lib-sftp, in preparation for further processing by Alma.

```mermaid
sequenceDiagram
accTitle: Diagram depicting processing of Bib exception reports from OCLC
accDescr {
- Alma submits Marc record updates to OCLC for datasync every Tuesday at 7 pm
- OCLC takes 4-6 hours to process the updates from Alma and create exceptions reports, which it puts on the OCLC sftp server
- This job
  - Downloads all "exception" files that have been created in the past week
  - Creates a Marc Collection with individual records for each MMS ID
    - Each stub Marc record has an 001 field with the MMS ID, and a 915 field with the information from the OCLC record about how the MMS ID was processed.
  - Temporarily writes file to disk on local file system
  - Uploads Marc files to lib-sftp
}
Alma->>OCLC: Alma submits Marc record updates to OCLC
OCLC->>OCLC-sftp: OCLC creates exception reports and deposits on OCLC-sftp
OCLC-sftp->>Lib Jobs: Lib jobs downloads exception reports from OCLC-sftp
Lib Jobs->>Lib Jobs: Creates a Marc Collection with individual records for each MMS ID with exception details in a 915 field
Lib Jobs->>Lib Jobs: Temporarily writes file to disk on local file system
Lib Jobs->>lib-sftp: Uploads marc files to lib-sftp
```
