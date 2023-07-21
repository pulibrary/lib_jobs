# Alma Normalization Process
  The purpose of this job is to move OCLC numbers from the 914 field into the 035 file and remove any existing 035 fields that have an OCLC field. The job is called via Alma's "config" API.  At some future time it may be utilized to disable accounts.

## Flow Diagrams


```mermaid
sequenceDiagram
    accTitle: Moving OCLC numbers from 914 field into the 035 file.
    accDescr {
      Every Thursday Lib Jobs creates an XML String that will be POSTed to the Config API. Lib Jobs then POSTs document to the config API. The job then logs a 200 response from Alma as success or records non 200 responses as a failure. Lib Jobs sends email responses for failed POSTs to Mark Zelesky and Peter Green with the reason for failure.
    }
    Lib Jobs->>+Lib Jobs: Creates an XML String on Thursdays at 11am UTC daily
    Lib Jobs->>+Alma: Send POST request containing XML String to the config API
    actor Mark Zelesky and Peter Green
    Alma->>+Lib Jobs: Responds with status code
    alt 200 response (success)      
      Lib Jobs->>Lib Jobs: Log response
    else non-200 response (failure)
      Lib Jobs->>Mark Zelesky and Peter Green: send email with reason for failure
    end
```
