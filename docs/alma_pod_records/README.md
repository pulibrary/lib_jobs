# Alma Pod Records

This job cleans up MARC records from Alma and sends them to the [POD project](https://github.com/pod4lib/aggregator/wiki).

Alma exports the MarcXML records through the "POD Project Publishing" publishing profile.

You can see all uploaded files in our [POD Aggregator Organization page](https://pod.stanford.edu/organizations/princeton).

## Flow Diagrams

```mermaid
sequenceDiagram
    Alma->>lib-sftp: Exports MaRC XML records(midnight daily Princeton time)
    Lib Jobs->>+lib-sftp: Request list of MaRC XML files (Daily at 11:30am UTC)
    lib-sftp-->>-Lib Jobs: list of non-empty MaRC XML files
    Lib Jobs->>+lib-sftp: Download MaRC XML file(s)
    lib-sftp-->>-Lib Jobs: MaRC XML file(s)
    Lib Jobs->>Lib Jobs: Add namespace to XML files
    Lib Jobs->>POD Aggregator: POST MaRC XML files
    ReShare->>+POD Aggregator: Harvests records
    POD Aggregator-->>-ReShare: MaRC records
```

## Publish the full dump from Alma
- Go to Alma -> Resources -> Publishing Profiles
- Click triple dots next to the Pod Project Publishing profile and select "Republish"
- For Publishing Mode select Rebuild Entire Index
- This process takes around [X] amount of time to run 
