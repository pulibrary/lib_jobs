# ILS Jobs

## Connects to
  * SFX
  * Voyager
  * Future Alma File integration

## Access Databases
  * Oracle
  * MySQL (MariaDB)

## Tasks
  * Statistics
  * Generate records from SFX
  * Download records from OCLC

## Output
  * tableau.princeton.edu
  * Google Drive
  * FTP files

## Prerequisites
- Ruby (3.1.0 or later)
- Postgres
  ```
  brew install postgres
  brew services start postgresql
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

Alternatively, in place of `bundle exec foreman start`, one may invoke the following for running the Rails server and Webpack separately:
```bash
bundle exec rails server
# And please invoke this in another terminal:
bundle exec webpack-dev-server
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
