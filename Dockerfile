FROM ruby:2.6.6

ARG cert_dir=./certs

COPY ${cert_dir}/ /usr/local/share/ca-certificates/
RUN update-ca-certificates

RUN apt-get update && apt-get install -y default-libmysqlclient-dev nodejs npm netcat tzdata git chromium && npm install -g yarn

RUN yarn config set cafile /etc/ssl/certs/ca-certificates.crt

COPY Gemfile Gemfile.lock yarn.lock /
RUN gem install bundler
RUN bundle install --jobs $(nproc)
RUN yarn install
ENV RAILS_LOG_TO_STDOUT true
