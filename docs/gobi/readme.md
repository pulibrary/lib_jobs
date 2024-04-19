# GOBI ISBN Holdings Job
This workflow gets the records of all items added to Alma in the last 5 years and creates an ISBN export file for export to GOBI. This is to help prevent us from purchasing an item we already own.

## Flow Diagram


```mermaid
sequenceDiagram
accTitle: Diagram depicting the generation and export of an ISBN file of items added to Alma in the last 5 years.
accDescr {
    Lib Jobs downloads a CSV file of items added to Alma in the last 5 years from LibSFTP weekly.
    Lib Jobs creates an ISBN file in the [format](https://connect.ebsco.com/s/article/GOBI-Library-Holdings-Load-Service?language=en_US) recommended by GOBI.
    Lib Jobs uploads the ISBN file to the GOBI SFTP server.
}
LibSFTP->>Lib Jobs: Lib Jobs downloads a CSV file of items added to Alma in the last 5 years from LibSFTP weekly
Lib Jobs->>Lib Jobs: Lib Jobs creates an ISBN file in the format recommended by GOBI
Lib Jobs ->>GOBI SFTP: Lib Jobs uploads the ISBN file to the GOBI SFTP server.
```
