# Alma Fund Adjustment
  This job moves Peoplesoft Transactions from Peoplesoft to Alma to keep the fund balances in Alma in sync with the fund balances in Peoplesoft.  These are any expeses not accounted for in Alma for material purchases like a book, or paying a UPS bill.

## Flow Diagrams


```mermaid
sequenceDiagram
    Peoplesoft->>Peoplesoft Samba Share: generates Fund Transaction csv file (2:30 princeton local time Daily)
    Lib Jobs->>+Peoplesoft Samba Share: request list of fund transaction csv files
    Peoplesoft Samba Share-->>-Lib Jobs: list of fund transaction csv files
    Lib Jobs->>Lib Jobs: Check for duplicate Transaction in the local database table peoplesoft_transactions
    alt ANY duplicate transaction    
      Lib Jobs->>Email Server: Sends Email to Student Accounts and PUL stakeholders
    else All new transactions
      Lib Jobs->>lib-sftp: upload fund transaction csv files
      alt No FTP error
      Lib Jobs->>Peoplesoft Samba Share: rename fund transaction csv files .processed
      else
        Lib Jobs->>Lib Jobs: log error
      end
    end
    Alma->>+lib-sftp: requests list of fund transaction csv file
    lib-sftp-->>-Alma: returns a list of fund transaction csv file
    Alma->>lib-sftp: rename the file to .handled
    Alma->>Alma: Process file to apply the transactions to the funds
    Alma->>Alma: Any errors are logged
```
