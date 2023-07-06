# Web Staff
  This generates the staff report that is read into the library website each day to make the [staff directory](https://library.princeton.edu/staff/directory).

## Flow Diagram

```mermaid
sequenceDiagram
    accTitle: Staff Report Generation by lib-jobs.
    accDescr {
      PeopleSoft puts the Active Library Staff Report on HR Reports Share (6am Princeton time Daily).
      Library website requests staff updates (6:30am Princeton time Daily) from Lib Jobs.
      Lib Jobs reads Active Library Staff Report from HR Reports Share, and responds to the library website with csv.
      Library website saves this csv file to feeds directory.
      Library website runs the PUL library staff Importer (every 12 hours).
    }

    PeopleSoft->>HR Reports Share: writes Active Library Staff Report (6am Princeton time Daily)
    Library Website->>+Lib Jobs: get staff updates (6:30am Princeton time Daily)
    Lib Jobs->>HR Reports Share: read Active Library Staff Report
    Lib Jobs-->>-Library Website: responds with csv 
    Library Website->>Library Website: saves csv to feeds directory
    Library Website->>Library Website: PUL library staff Importer (every 12 hours)
```

### Key
[get staff updates](https://github.com/pulibrary/princeton_ansible/blob/main/roles/libwww/files/get_staff_updates.sh)

[PUL library staff Importer](https://library.princeton.edu/admin/structure/feeds/pul_library_staff_importer/tamper)
