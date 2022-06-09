# Alma Renew
  This automatically renews items in Alma via NCIP calls

## Flow Diagrams


```mermaid
sequenceDiagram
    Alma->>lib-sftp: Analytics generates a report of all items waiting to be renewed
    Lib Jobs->>+lib-sftp: request list of items to be renewed at 13:00 (pm) UTC daily
    lib-sftp-->>-Lib Jobs: list of renew items CSV files
    Lib Jobs->>Lib Jobs: converts item to NCIP call
    Lib Jobs->>Alma: send renew via NCIP
    alt NCIP error
      Lib Jobs->>Lib Jobs: log error      
    end
    Lib Jobs->>lib-sftp: rename list of renew items CSV to .processed
```
