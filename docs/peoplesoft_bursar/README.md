# PeopleSoft Bursar
  This job moves fines and credits from Alma to student accounting.  Fines are not generated for staff and faculty.  Folks in finance have access to the end product, but other do not have access to the system.

## Flow Diagrams

### Fines Process
```mermaid
sequenceDiagram
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
