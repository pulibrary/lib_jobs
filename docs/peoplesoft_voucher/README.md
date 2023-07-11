# PeopleSoft Voucher
  This job transforms invoices from Alma to vouchers for peoplesoft.  Invoices are ready to be sent to peoplesoft when staff approve an invoice for payment.  These invoices can be for physical items, shipping changes, or anything really.

## Flow Diagrams

```mermaid
sequenceDiagram
    accTitle: Transformation of invoices from Alma to vouchers for PeopleSoft.
    accDescr {
      Alma exports Invoices for Payment job to lib-sftp (7pm Princeton time Daily)
      Lib Jobs requests and receives a list of invoice xml files (Daily at 2:00 UTC) from lib-sftp. Lib Jobs downloads these xml file(s) from lib-sftp.
      If valid invoice lines exist, Lib Jobs shares the Voucher Report and Onbase Report with Voucher Samba Share.
      Lib Jobs sends emails to PUL stakeholders and renames the invoice xml file(s) to .processed in lib-sftp.
      At this stage, if valid invoice lines exist, Peoplesoft downloads and processes the Voucher Report from Voucher Samba Share.
      Peoplesoft stages vouchers for prod to process for payment.
      Onbase downloads and processes the Onbase Report from Voucher Samba Share. Onbase then updates invoices with the voucher ID and finally sends emails to PUL Stakeholders.
    }
    Alma->>lib-sftp: Export Invoices for Payment job f(7pm Princeton time Daily)
    Lib Jobs->>+lib-sftp: request list of invoice xml files (Daily at 2:00 UTC)
    lib-sftp-->>-Lib Jobs: list of invoice xml files
    Lib Jobs->>+lib-sftp: download invoice xml file(s)
    lib-sftp-->>-Lib Jobs: invoice xml file(s)
    alt valid invoice lines exist 
    Lib Jobs->>Voucher Samba Share: Voucher Report
    Lib Jobs->>Voucher Samba Share: Onbase Report
    end
    Lib Jobs->>Email Server: Sends Email PUL stakeholders
    Lib Jobs->>lib-sftp: rename invoice xml files to .processed
    alt valid invoice lines exist
    Peoplesoft->>Voucher Samba Share: downloads and process Voucher Report
    Peoplesoft->>Peoplesoft: Stages vouchers for prod to process for payment
    Onbase->>Voucher Samba Share: Downloads and processes Onbase report
    Onbase->>Onbase: Updates invoices with the voucher id
    Onbase->>Email Server: Sends Email to PUL Stakeholders
    end
```
## Turning the job on and off

To turn this job on or off:
1. Go to [the flipflop dashboard](https://lib-jobs.princeton.edu/features)
1. In the active_record column, press the on or off button
