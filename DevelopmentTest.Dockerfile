FROM ruby:2.6.6

ARG cert

RUN echo "${cert}" > /usr/local/share/ca-certificates/ca-certificates.crt
RUN update-ca-certificates

RUN apt-get update && apt-get install -y default-libmysqlclient-dev nodejs npm tzdata git chromium && npm install -g yarn

RUN yarn config set cafile /etc/ssl/certs/ca-certificates.crt

COPY Gemfile Gemfile.lock /
RUN gem install bundler
RUN bundle install --jobs $(nproc)
ENV RAILS_LOG_TO_STDOUT true
