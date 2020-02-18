# README

This is a prototype Rails application for tracking the 2019 novel coronavirus

## Installing and Running
#####To Install
```bash
bundle install
yarn install
```
#####To Setup Database
```bash
bundle exec rake db:drop db:create db:migrate db:setup
```
Note: Make sure you have a Postgres database running

#####To Run
```bash
bundle exec rails s
```

#####To Populate Demo Database
```bash
bundle exec rake demo:setup
bundle exec rake demo:populate
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


