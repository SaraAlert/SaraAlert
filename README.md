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
