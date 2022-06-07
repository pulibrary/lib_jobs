# Alma People
  This job moves updates from Peoplesoft API Store to Alma to keep the accounts in alma up to date.  This currently just adds accounts.  At some future time it may be utilized to disable accounts.

## Flow Diagrams


```mermaid
sequenceDiagram
    Lib Jobs->>+Peoplesoft API Store: Requests a List of new People at 12:45am UTC daily
    Peoplesoft API Store->>-Lib Jobs: Returns a JSON List of new People
    Lib Jobs->>Lib Jobs: Converts JSON to People Alma XML
    Lib Jobs->>Lib Jobs: zip People Alma XML
    alt Blank File    
      Lib Jobs->>Lib Jobs: Do Nothing (skip)
    else All new transactions
      Lib Jobs->>lib-sftp: upload zipped People Alma XML file
    end
    Alma->>+lib-sftp: requests list of zipped People Alma XML files
    lib-sftp-->>-Alma: returns a list of zipped People Alma XML files
    Alma->>lib-sftp: rename the file to .handled
    Alma->>Alma: Process file to add or update accounts for each person in the XML file
    Alma->>Alma: Any errors are logged
```
