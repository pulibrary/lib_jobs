# Alma People
  This job moves updates from Peoplesoft API Store to Alma to keep the accounts in alma up to date.  This currently just adds and updates accounts.  At some future time it may be utilized to disable accounts.

## Flow Diagrams


```mermaid
sequenceDiagram
    accTitle: Moving updates from Peoplesoft API Store to Alma to keep the accounts in alma up to date.
    accDescr {
      Lib Jobs requests a List of new and updated People at 12:45am UTC daily from Peoplesoft API Store. A JSON List of new and updated People is returned.
      For each person in th JSON file, if expiration dates are Nil then Lib Jobs sends email to PUL stakeholders. Otherwise, it converts JSON to Alma Patron XML format.
    Lib Jobs zips Alma Patron XML and uploads the zipped file to lib-sftp if there are any updated or new people.
    Alma requests lib-sftp for a list of zipped Alma Patron XML files. This is returned, and renamed to .handled.
    Alma adds or updates accounts for each person in the XML file (SIS integration). Any errors are logged.
    }
    Lib Jobs->>+Peoplesoft API Store: Requests a List of new and updated People at 12:45am UTC daily
    Peoplesoft API Store->>-Lib Jobs: Returns a JSON List of new and updated People
    loop Each person in the JSON file
      alt Nil expiration dates
        Lib Jobs->>Email Server: Sends email to PUL stakeholders
      else
        Lib Jobs->>Lib Jobs: Converts JSON to Alma Patron XML format
      end
    end
    Lib Jobs->>Lib Jobs: zip Alma Patron XML
    alt Blank File    
      Lib Jobs->>Lib Jobs: Do Nothing (skip)
    else Any updated or new people
      Lib Jobs->>lib-sftp: upload zipped Alma Patron XML file
    end
    Alma->>+lib-sftp: requests list of zipped Alma Patron XML files
    lib-sftp-->>-Alma: returns a list of zipped Alma Patron XML files
    Alma->>lib-sftp: rename the file to .handled
    Alma->>Alma: SIS integration adds or updates accounts for each person in the XML file
    Alma->>Alma: Any errors are logged
```

* SIS stands for Student Information System.
* To check the status in Alma, go to Admin > Monitor Jobs > History Tab. Search for a job named "Users SYNCHRONIZE using profile Student Information System".
* To check the Peoplesoft API store, go to https://api-store.princeton.edu/store. Log in using the "Library Api Store User" credentials from Lastpass. Under Applications, choose AlmaDailyPatronFeed and generate a new token. Under APIs, you can use that token in the Swagger UI to interact with the LibAlma API.
