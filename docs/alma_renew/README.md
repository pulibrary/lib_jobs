# Alma Renew
  This automatically renews items in Alma via NCIP calls

## Flow Diagrams


```mermaid
sequenceDiagram
    Alma->>lib-sftp: Analytics generates a report of all Alma items waiting to be renewed
    Lib Jobs->>+lib-sftp: request list of items to be renewed at 13:00 (pm) UTC daily
    lib-sftp-->>-Lib Jobs: list of renew items CSV files
    loop Each item
      alt Missing request expiration date or user id
        Lib Jobs->>Lib Jobs: log error
      else
        Lib Jobs->>Lib Jobs: converts item to an NCIP XML call
      end
      Lib Jobs->>+Alma: send renewals via NCIP
      Alma-->>-Lib Jobs: NCIP renewal status
      alt NCIP renewal error
        Lib Jobs->>Lib Jobs: log error      
      end
    end
    Lib Jobs->>lib-sftp: rename list of renew items CSV to .processed
```
