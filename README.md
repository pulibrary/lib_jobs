# ILS Jobs

## Connects to
  * SFX
  * Voyager
  * Future Alama File integration

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
- Ruby (2.6.6 or later 2.6.z releases)

## Getting Started

```bash
bundle install
yarn install
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

### Linting with Rubocop

```bash
bundle exec rubocop -a
```

### Running the RSpec test suites

```bash
bundle exec rspec
```
