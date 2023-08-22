# ILS Jobs

## Connects to
  * Alma SFTP for file based integrations
  * Alma NCIP 
  * OCLC SFTP Server
  * Archivesspace API
  * Alma APIs to start of jobs
  * OIT Person API
  * Data Warehouse File Server
  * Peoplesoft File Server
  * Ombase
  * SCSB Middleware S3 Server
  * Platform for Open Data (POD) API
  * Springshare Libguides and Libcal APIs
  * Library 

## Tasks
  * Alma Fund Adjustment
  * Alma Invoice Status
  * Alma Oclc Number Normalization
  * Alma renewal of SCSB partner materials via NCIP
  * Alma Patron Adds/Updates
  * Peoplesoft Bursar Transfer
  * Peoplesoft Vocher Feed
  * Aspace2Alma Collection Record Synchronization
  * SCSB SubmitCollection Record Updates
  * POD Marc Record Adds/Updates
  * OCLC Data Sync Successful Record Update Processing
  * OCLC Data Sync Failed Record Update Processing
  * Library Current Event List
  * Library Databases List Publishing
  * Library Staff List 

## Output
  * CSV Files for download by other applications
  * Various text file formats for SFTP/Fileshare Processing
  * MarcXML for various purposes

## Prerequisites
- Ruby (3.1.0 or later)
- Python (3.11.1 or later)
- Postgres
  ```
  brew install postgresql@version-number
  brew services start postgresql@version-number
  ```

## Staging Mail Catcher
To See mail that has been sent on the staging server you must ssh tunnel into the server

ssh -L 1082:localhost:1080 pulsys@lib-jobs-staging1
Once the tunnel is open you can see the mail that has been sent on staging [here](localhost:8082)

## Getting Started

```bash
bundle install
yarn install
bundle exec rake db:create db:migrate
bundle exec rake servers:start
bundle exec foreman start
bundle exec rails db:seed
```

Then please visit the server running locally at [http://localhost:3000](http://localhost:3000)

### Run mailcatcher 
The mailcatcher gem ensures you do not accidentally send test emails to actual people

1. run once: `gem install mailcatcher`
1. run every time: `mailcatcher`
1. you can see the mail that has been sent at http://127.0.0.1:1080

### Linting with Rubocop

```bash
bundle exec rubocop -a
```

### Running the RSpec test suites

```bash
bundle exec rspec
```

### Brakeman

Run brakeman normally; to ignore false positives run

`brakeman -I`

See [brakeman ignoring false positives documentation](https://brakemanscanner.org/docs/ignoring_false_positives/)
