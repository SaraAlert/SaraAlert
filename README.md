![Sara Alert](https://user-images.githubusercontent.com/14923551/76420768-025c0880-6379-11ea-8342-0a9aebd9d287.png)

![Build](https://img.shields.io/travis/com/SaraAlert/SaraAlert/master?style=flat-square)
![Tag)](https://img.shields.io/github/v/tag/SaraAlert/SaraAlert?style=flat-square)
![License](https://img.shields.io/github/license/SaraAlert/SaraAlert?style=flat-square)

Sara Alert is an open source tool built to allow public health officials to monitor potentially exposed individuals (“monitorees”, e.g., contacts of cases or travelers from affected areas) over time for symptoms by enrolling them in the system. During enrollment, the potentially exposed individual indicates their preferred method for daily contact. The enrolled monitoree receives a daily reminder from Sara Alert to enter temperature and any symptoms. If any symptoms are reported, the public health official receives an alert in order to coordinate care. If the monitoree fails to report, the public health official can follow up after a pre-defined period. Public health officials have access to reports and aggregated data based on their level of access.

Sara Alert was built in response to the COVID-19 outbreak, but was designed to be customizable such that it can be deployed to support future outbreaks.

[![mitre](https://user-images.githubusercontent.com/14923551/77242919-240b8a00-6bda-11ea-887d-2a42919eb6fb.jpg)](https://www.mitre.org/)


## Installing and Running

Sara Alert is a Ruby on Rails application that uses the PostgreSQL database for data storage and Redis for message processing.

### Prerequisites

To work with the application, you will need to install some prerequisites:

* [Ruby](https://www.ruby-lang.org/)
* [Bundler](http://bundler.io/)
* [Postgres](http://www.postgresql.org/)
* [Redis](https://redis.io)

### Development Installation

#### Application

Run the following commands from the root directory to pull in both frontend and backend dependencies:

* `bundle install`
* `yarn install`

#### Database

Run the following command from the root directory to intialize the database (note: make sure you have a Postgres database running):

* `bundle exec rake db:drop db:create db:migrate db:setup`
* `bundle exec rake admin:import_or_update_jurisdictions`
* (optional) `bundle exec rake demo:setup demo:populate`

#### ActiveJob + Sidkiq + Redis + Whenever

ActiveJob will work with Sidekiq, Redis, and Whenever to manage the queueing and running of jobs (used to send emails, SMS, and other methods of notification).

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

##### Whenever

The [Whenever](https://github.com/javan/whenever) gem is used to schedule jobs. This gem uses the contents of `config/schedule.rb` to generate a crontab file. These jobs include:

* Automatically closing out monitorees after the monitoring period
* Purging old monitoree records
* Updating system analytics

You must update your chrontab for these jobs to run periodically (defined in `config/schedule.rb`). To do so run:

```
bundle exec whenever --update-crontab
```

#### Running

To run Sara Alert, execute: `bundle exec rails s`.

### Installation (Docker)

#### Getting Started

Ensure [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) are installed.

This application includes several Dockerfiles and Docker Compose configurations. Let's go over each of them:

* `Dockerfile`: This Dockerfile is essentially the same as the `DevelopmentTest.Dockerfile` but provides support for developers that want to get a development and test environment up and running with a simple `docker build .`
* `DevelopmentTest.Dockerfile`: This Dockerfile is used in the project's Continuous Integration (CI) and allows developers to get started with the full split stack architecture as its the default used in the compose files. It contains the dependencies for running tests.
* `Production.Dockerfile`: This Dockerfile is built for production or staging deployments.
* `docker-compose.yml`: This docker compose file sets up the numerous containers, networks, and volumes required for the split architecture.
* `docker-compose.prod.yml`: The only difference between this file and the normal one is the overwriting of the `DevelopmentTest` image tag with the `latest` tag.

##### Building for Staging

If you are building the image behined a corporate proxy:
* Create a `certs/` directory in the root of the project
* Place your company `.crt` file in it
* `export CERT_PATH=/path/to/crt_from_above.crt`

Building for staging requires the use of the `Production.Dockerfile`.

* `docker build -f Production.Dockerfile --tag sara-alert:latest --build-arg cert="$(cat $CERT_PATH)" .`

##### Deploying Staging

Deploying a staging server is done with `docker-compose.yml`, `docker-compose.prod.yml`, and the image created in the previous section. Make sure the image is on the staging server or it can be pulled from a Docker registry to the staging server.

**Environment Variable Setup**

To set up Sara Alert in a staging configuration, generate two environment variable files: `.env-prod-assessment` and `.env-prod-enrollment`. The content for these files can be based off of the `.env-prod-assessment-example` and `.env-prod-enrollment-example` files. The `SECRET_KEY_BASE` and `POSTGRES_PASSWORD` variables should be changed at the very least. It is also important to note that `SARA_ALERT_REPORT_MODE` should be set to `false` for the enrollment file and `true` for the assessment file.

**Container Dependencies**

Create a directory for the deployment. Move both docker compose files and both environment variable files from the previous section into this folder. Within this deployment directory, create a subdirectory called `tls` and place your `.key` and `.crt` files for the webserver inside. Name the files `puma.key` and `puma.crt`. Ensure the files within the `tls` directory are at least `0x004` permissions so they can be read inside the container.

**Deployment**

Before any of the following commands, export the image you're working with. For the staging environment, the tag is assumed to be `latest`. Example for a locally built image (you will likely need to update this to point to your registry!): `export SARA_ALERT_IMAGE=sara-alert`

* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml pull`
* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --remove-orphan`
* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml run sara-alert-enrollment bin/bundle exec rake db:create`
* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml run sara-alert-enrollment bin/bundle exec rake db:migrate`
* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml run sara-alert-assessment bin/bundle exec rake db:create`
* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml run sara-alert-assessment bin/bundle exec rake db:migrate`

**Post-deployment Setup**

Before any of the following commands, export the image you're working with. For the staging environment, the tag is assumed to be `latest`. Example for a locally built image (you will likely need to update this to point to your registry!): `export SARA_ALERT_IMAGE=sara-alert`

Load Jurisdictions:

* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml run sara-alert-enrollment bin/bundle exec rake admin:import_or_update_jurisdictions`
* `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml run sara-alert-assessment bin/bundle exec rake admin:import_or_update_jurisdictions`

Setup the demonstration accounts and population:

* Launch a shell inside the sara-alert-enrollment container: `/usr/local/bin/docker-compose -f docker-compose.yml -f docker-compose.prod.yml run sara-alert-enrollment /bin/sh`
* Remove the protections for running the demonstration setup tasks only in development mode:
  * `vi lib/tasks/demo.rake`
  * Delete the environment checks at the top of the `setup` and `populate` tasks
  * Save and close the file
* Execute the demonstration rake tasks:
  * `bin/bundle exec rake demo:setup`
  * `bin/bundle exec rake demo:populate`
* Exit the container with `exit`

The applications should be running on port 443 and 4343.

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
