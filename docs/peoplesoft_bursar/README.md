# PeopleSoft Bursar
  This job moves fines and credits from Alma to student accounting.  Fines are not generated for staff and faculty.  Folks in finance have access to the end product, but other do not have access to the system.

## Flow Diagrams

### Fines Process
```mermaid
sequenceDiagram
    accTitle: Procedure for moving fines from Alma to student accounts.
    accDescr {
      Alma runs scheduled analytics report for fines (6am Princeton time daily) to lib-sftp.
      Lib Jobs requests list of fine csv files from lib-sftp (Tuesday 14:30 UTC), and downloads this list.
      If report lines exist, Lib Jobs sends a Fine Report to Bursar Samba Share and sends Email to Student Accounts and PUL stakeholders.
      Otherwise, Lib Jobs sends Email to PUL stakeholders.
      Lib Jobs renames the csv file to .processed via lib-sftp.
      If student accounts received an email, Bursar downloads and processes fine report from Bursar Samba Share. These fines are applied to Student accounts.
    }
    Alma->>lib-sftp: run scheduled analytics report for fines (6am Princeton time daily)
    Lib Jobs->>+lib-sftp: request list of fine csv files (Tuesday 14:30 UTC)
    lib-sftp-->>-Lib Jobs: list of fine csv files
    Lib Jobs->>+lib-sftp: download fine csv file(s)
    lib-sftp-->>-Lib Jobs: fine csv file(s)
    alt report lines exist
    Lib Jobs->>Bursar Samba Share: Fine Report
    Lib Jobs->>Email Server: Sends Email to Student Accounts and PUL stakeholders
    else No report lines exist
    Lib Jobs->>Email Server: Sends Email to PUL stakeholders
    end
    Lib Jobs->>lib-sftp: rename fine csv to .processed
    alt Student Accounts received email
    Bursar->>Bursar Samba Share: download and process Fine Report
    Bursar->>Bursar: Fines Applied to Student Accounts
    end
```

### Credits Process
```mermaid
sequenceDiagram
    accTitle: Procedure for moving credits from Alma to student accounts.
    accDescr {
      Alma sends bursar export job for Credits (9pm Princeton time Daily) to lib-sftp.
      Lib Jobs requests list of credit xml files from lib-sftp (Thursday 14:30 UTC), and downloads this list.
      If report lines exist, Lib Jobs sends a Fine Report (Credits are negative fines) to Bursar Samba Share and sends Email to Student Accounts and PUL stakeholders.
      Otherwise, Lib Jobs sends Email to PUL stakeholders.
      Lib Jobs renames the credit xml files to .processed via lib-sftp.
      If student accounts received an email, Bursar downloads and processes fine report from Bursar Samba Share. These credits are applied to Student accounts.
    }
    Alma->>lib-sftp: bursar export job for Credits (9pm Princeton time Daily)
    Lib Jobs->>+lib-sftp: request list of credit xml (Thursday 14:30 UTC)
    lib-sftp-->>-Lib Jobs: list of credit xml files
    Lib Jobs->>+lib-sftp: download credit xml file(s)
    lib-sftp-->>-Lib Jobs: credit xml file(s)
    alt report lines exist
    Lib Jobs->>Bursar Samba Share: Fine Report (Credits are negative fines)
    Lib Jobs->>Email Server: Sends Email to Student Accounts and PUL stakeholders
    else No report lines exist
    Lib Jobs->>Email Server: Sends Email to PUL stakeholders
    end
    Lib Jobs->>lib-sftp: rename credit xml files to .processed
    alt Student Accounts received email
    Bursar->>Bursar Samba Share: download and process Fine Report
    Bursar->>Bursar: Credits Applied to Student Accounts
    end
```
