![Sara Alert](https://user-images.githubusercontent.com/14923551/76420768-025c0880-6379-11ea-8342-0a9aebd9d287.png)

[![Build Status](https://travis-ci.com/SaraAlert/SaraAlert.svg?branch=master)](https://travis-ci.com/SaraAlert/SaraAlert)
[![codecov](https://codecov.io/gh/SaraAlert/SaraAlert/branch/master/graph/badge.svg)](https://codecov.io/gh/SaraAlert/SaraAlert)

Sara Alert is an open source tool built to allow public health officials to monitor potentially exposed individuals (“monitorees”, e.g., contacts of cases or travelers from affected areas) over time for symptoms by enrolling them in the system. During enrollment, the potentially exposed individual indicates their preferred method for daily contact. The enrolled monitoree receives a daily reminder from Sara Alert to enter temperature and any symptoms. If any symptoms are reported, the public health official receives an alert in order to coordinate care. If the monitoree fails to report, the public health official can follow up after a pre-defined period. Public health officials have access to reports and aggregated data based on their level of access.

Sara Alert was built in response to the COVID-19 outbreak, but was designed to be customizable such that is can be deployed to support future outbreaks.

![ConOps](https://user-images.githubusercontent.com/14923551/76426329-4c48ec80-6381-11ea-819e-fcef98c66a2a.png)

Created by [The MITRE Corporation](https://www.mitre.org).

## Installing and Running

Sara Alert is a Ruby on Rails application that uses the PostgreSQL database for data storage.

### Prerequisites

To work with the application, you will need to install some prerequisites:

* [Ruby](https://www.ruby-lang.org/)
* [Bundler](http://bundler.io/)
* [Postgres](http://www.postgresql.org/)

### Installation

#### Application

Run the following commands from the root directory to pull in both frontend and backend dependencies:

* `bundle install`
* `yarn install`

#### Database

Run the following command from the root directory to intialize the database (note: make sure you have a Postgres database running):

* `bundle exec rake db:drop db:create db:migrate db:setup`
* `bundle exec rake admin:import_or_update_jurisdictions`
* (optional) `bundle exec rake demo:setup demo:populate`

#### ActiveJob + Sidkiq + Redis

ActiveJob will work with Sidekiq and Redis to manage the queueing and running of jobs (used to send emails, SMS, and other methods of notification).

##### Redis

Redis will need to be installed and running. To install Redis:

```bash
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
```

To start Redis:

```
redis-server
```

##### Sidekiq

Sidekiq is the queueing system that ActiveJob interfaces with. Sidekiq should be installed when you ran `bundle install` in the application installation instructions. To start Sidekiq, and make it aware that it is responsible for the mailers queue, execute the following:

```
bundle exec sidekiq -q default -q mailers
```

#### Whenever

The [Whenever](https://github.com/javan/whenever) gem is used to schedule ActiveJobs (for things like closing out monitorees that no longer need to be monitored). This gem uses the contents of `config/schedule.rb` to generate a crontab file.
To update your chrontab (to periodically perform the jobs defined in `config/schedule.rb`), run `bundle exec whenever --update-crontab`.

#### Running

To run Sara Alert, execute: `bundle exec rails s`.

### Installation (Docker)

This application includes a Docker Compose configuration. To get started, do the following:

* Ensure [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) are installed.
* Generate an `.env-prod` file. To see an example of what needs to be in that file, view `.env-prod-example`. The `SECRET_KEY_BASE` and `POSTGRES_PASSWORD` variables should be changed at the very least.
* `docker-compose build .`
* `docker-compose down` (if it's already running)
* `docker-compose up -d --force-recreate` (-d starts it daemonized, --force-recreate makes it grab the new build)
* (optional) `docker-compose logs -f` will follow the log files as these containers are started
* `docker-compose exec sara-alert rake db:create db:migrate RAILS_ENV=production`
* `docker-compose exec sara-alert rake admin:import_or_update_jurisdictions RAILS_ENV=production` will build the jurisdictional structure
* (optional) `docker-compose exec sara-alert rake demo:setup demo:populate RAILS_ENV=production` will populate the database with demonstration (fake) data and accounts

## Testing

### Backend Tests

```
bundle exec rails test
```

### System Tests

By default, `rails test` will not run system tests. To run system tests (uses Selenium):

```
bundle exec rails test:system
```

## Configuration

### Jurisdiction and Symptom Configuration

All jurisdictions, jurisdictional hierarchies, jurisdictional symptoms-to-be-monitored, and symptom thresholds are defined in the configuration file located at `config/sara/jurisdictions.yml`. See this file for more details about the structure and definition required by Sara Alert.

#### Applying Changes

You must run `bundle exec rake admin:import_or_update_jurisdictions` in order for changes made in the `config/sara/jurisdictions.yml` configuration to take effect.

## Reporting Issues

To report issues with the Sara Alert code, please submit tickets to [GitHub](https://github.com/SaraAlert/SaraAlert/issues).

## Version History

This project adheres to [Semantic Versioning](http://semver.org/).

Releases are documented in the [CHANGELOG.md](https://github.com/SaraAlert/SaraAlert/blob/master/CHANGELOG.md).

## License

Copyright 2020 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

```
http://www.apache.org/licenses/LICENSE-2.0
```

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
