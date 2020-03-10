# README

This is a prototype Rails application for tracking the 2019 novel coronavirus

## Installing and Running
##### To Install
```bash
bundle install
yarn install
```
##### To Setup Database
```bash
bundle exec rake db:drop db:create db:migrate db:setup
```
Note: Make sure you have a Postgres database running

##### To Run
```bash
bundle exec rails s
```

##### To Populate Demo Database
```bash
bundle exec rake admin:import_or_update_jurisdictions 
bundle exec rake demo:setup
bundle exec rake demo:populate
```

## Jurisdiction and Symptom Configuration
The jurisdictions used on they system and the symptoms  and symptoms thresholds are configured in the file `config/sara/jurisdictions.yml`. 
#### Applying Changes 
You must run `bundle exec rake admin:import_or_update_jurisdictions` in order for changes made to the jurisdictions.yml to take effect
#### Jurisdiction and Symptom Configuration Mechanics
The jurisdictions in the configuration file follows a hierarchical structure. A jurisdiction  has a name, which  is the key and two optional values,  `symptoms` and `children`. `symptoms` defines the symptoms that the jurisdiction which they belong to would like to track, said jurisdiction will track the  symptoms that it specifies ***IN ADDITION TO*** the symptoms
specified by all of it's parent jurisdictions. A `symptom` will be identified by it's name, which is the key in the symptom object, a `value` and a `type`. The `value` of a symptom defines the threshold of the symptom, this is the value that is considered as symptomatic for the symptom which it is defining. For float and integer symptoms, a reported symptom greater than or equal to the specified `value` wil be considered as symptomatic. Available values for the `type` field in a symptom are `FloatSymptom`, `IntegerSymptom`, or `BoolSymptom`. The `children` of a jurisdiction are nested jurisdictions that may have their own `symptoms` and/or `children`.

#### Example Use:
In the configuration below, the USA jurisdiction will have 3 symptoms, these symptoms will apply to the USA jurisdiction as well as ALL of it's nested children, meaning that all jurisdictions all the way down to the county-level jurisdictions will inherit these symptoms. State 1 has specified it's own symptoms which will be added to the symptoms that it inherited from its parent jurisdiction, these symptoms will be applied to State 1, and the children of State1 (County 1  and County 2). In other words, a monitoree in State 1, County 1 or County 2 will be asked about the symptoms Temperature, Cough, Difficulty Breathing and Vomit as part of their assessment, whereas a monitoree in State 2 or County 3 would only be asked about the symptoms Temperature, Cough and Difficulty Breathing as part of their assessment.

```
'USA':
    symptoms: 
        'Temperature': 
            value: 100.4
            type: 'FloatSymptom'
        'Cough':
            value: true
            type: 'BoolSymptom'
        'Difficulty Breathing':
            value: true
            type: 'BoolSymptom'
    children:
        'State 1':
            symptoms: 
              'Vomit':
                value: true
                type: 'BoolSymptom'
            children:
                'County 1':
                'County 2':
        'State 2':
            children:
                'County 3':
```

## ActiveJob + Sidkiq + Redis
ActiveJob will work with Sidekiq and Redis to manage the queueing and running of jobs.
### Redis
Redis will need to be running on your machine
To install redis:
```bash
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make
```
To start redis:
```
redis-server
```
### Sidekiq
Sidekiq is the queueing system that ActiveJob interfaces with.
Sidekiq should be installed when you run `bundle install`
You will have to start sidekiq independent of the app, you'll have to make sure that sidekiq is aware that it is responsible for the mailers queue.
`bundle exec sidekiq -q default -q mailers`


## Whenever
The [whenever gem](https://github.com/javan/whenever) is what we are using to schedule ActiveJobs.
This gem uses the contents of `config/schedule.rb` to generate a crontab file.
If you make changes to this file make sure to run `bundle exec whenever --update-crontab`


### Docker

##### Building Docker Image Behind Corperate Proxy
1. Put your root cert(s) in a certs/ directory in a file named ca-certificates.crt
2. Pass the certs directory to docker build as an argument named `cert_dir`
```bash
docker build --build-arg cert_dir=./certs  .
```
***Note if building image via docker-compse certs are expected to be in a root-level directory named `certs`

##### Running App Using Docker-Compose
To get this working in Docker:

* Ensure docker and docker-compose are installed on your machine
* Generate an `.env-prod` file. To see an example of what needs to be in that file, view `.env-prod-example`. The `SECRET_KEY_BASE` and `POSTGRES_PASSWORD` variables should be changed at the very least
* `docker-compose build .`
* `docker-compose down` (if it's already running)
* `docker-compose up -d --force-recreate` (-d starts it daemonized, --force-recreate makes it grab the new build you just did)
* `docker-compose logs -f` will follow the log files as these containers are started
* `docker-compose exec disease-trakker /usr/bin/rake db:create db:migrate RAILS_ENV=production`
* `docker-compose exec disease-trakker /usr/bin/rake demo:populate demo:setup RAILS_ENV=production`
* `docker-compose exec disease-trakker /usr/bin/rake mailers:test_send_enrollment_email RAILS_ENV=production`

### Setting this up on Nightingaledemo-dev
* Installed docker-compose from this guide: https://docs.docker.com/compose/install/
* Added a `docker` group, and added myself (mokeefe) to it
* `cd /etc/httpd/conf.d` to get to the apache conf directory
* `mv welcome.conf welcome.conf.bak` to get rid of the "apache is working" starter page
* Copy the following into the terminal:
 ```ApacheConf
cat <<EOT >> sara.conf
  <VirtualHost *:80>
    ServerName saraalert.mitre.org
    ServerAlias nightingaledemo-dev.mitre.org
    ServerAlias diseasetrakkerdemo.mitre.org

    ProxyPass / http://localhost:3000/

    ProxyPassReverse / http://localhost:3000/
  </VirtualHost>
EOT
```
* `sudo service httpd restart` to make the updates take
* `cd /etc/postfix` to get to the postfix conf directory
* in `main.cf`:
* find the host address by finding the ip for `docker0` from `ip a`, e.g. `172.17.0.1`
* Add that host address to the `inet_interfaces` variable, e.g. `localhost, 172.17.0.1`
* Then add the /16 subnet to `mynetworks`, e.g. `localhost, 172.17.0.0/16`
* Add iptables rules to allow smtp connections on all interfaces except the externally facing ethernet: `sudo iptables -I INPUT -i ens33 -p tcp --dport 25 -j DROP` and `sudo iptables -I INPUT 2 -p tcp --dport 25 -j ACCEPT`
* Save the iptables config to persist through reboots: `sudo iptables-save`

## Testing

### System Tests
By default, `rails test` will not run system tests. To run:
```
rails test:system
```