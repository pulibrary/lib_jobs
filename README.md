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

## Absolute ID (`AbID`) Management

There exists a set of features which are available for the generation and
synchronization of local identifiers used in order to provide locations for
physical items shelved within Special Collections and the Seeley G. Mudd Library.
These identifiers are generated and maintained as `AbIDs`, and there exists
support for synchronizing these with encoded archival description (EAD) records
serving as finding aids within a staging installation of [ArchivesSpace](https://archivesspace.org/).

### Local Development

By default, the support for `AbIDs` is configured to synchronize with the
ArchivesSpace REST API exposed on an installation deployed on `localhost` bound
to the port `8089`. For the purposes of testing within a `staging` environment,
there also exists an installation available at `https://aspace-staging.princeton.edu/staff/api`:

```bash
export ASPACE_URL="https://aspace-staging.princeton.edu/staff/api"
export ASPACE_USER=pulfalight_system
export ASPACE_PASSWORD=$SECRET
bundle exec rails server
```
...where `$SECRET` is a password tracked within LastPass.

One may also modify the configuration file tracked at `config/config.yml`:

```yaml
---
defaults: &defaults
  archivesspace:
    source:
      base_uri: <%= ENV["ASPACE_URL"] %>
      username: <%= ENV["ASPACE_USER"] || 'admin' %>
      password: <%= ENV["ASPACE_PASSWORD"] || 'secret' %>
```

For reference, please find the documentation for the ArchivesSpace REST API at the URL https://archivesspace.github.io/archivesspace/api.

#### Example Finding Aid Resources and TopContainers

There currently exist three encoded archival description Resource records on
the staging ArchivesSpace, which lie within the [`univarchives` Repository](https://aspace-staging.princeton.edu/staff/repositories/4):

- [ABID001](https://aspace-staging.princeton.edu/staff/resources/4188#tree::resource_4188)
- [ABID002](https://aspace-staging.princeton.edu/staff/resources/4189#tree::resource_4189)
- [ABID003](https://aspace-staging.princeton.edu/staff/resources/4190#tree::resource_4190)

One should be able to freely browse these and view the TopContainers linked to
the child Resources to any of these finding aids, some of which include:

- https://aspace-staging.princeton.edu/staff/top_containers/118091
- https://aspace-staging.princeton.edu/staff/top_containers/118092
- https://aspace-staging.princeton.edu/staff/top_containers/118116
- https://aspace-staging.princeton.edu/staff/top_containers/118117
- https://aspace-staging.princeton.edu/staff/top_containers/118216
- https://aspace-staging.princeton.edu/staff/top_containers/118120
