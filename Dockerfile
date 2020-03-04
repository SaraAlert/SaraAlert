ARG cert_dir

# Pinned to the latest ruby 2.6.0 version of the Passenger base Docker image
FROM phusion/passenger-ruby26:1.0.6

# Add certs and configure yarn
COPY ${cert_dir}/ /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Install node, tzdata, and yarn
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y nodejs tzdata yarn
RUN rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES 1

RUN mkdir /home/app/disease-trakker

WORKDIR /home/app/disease-trakker

# Add the Gemfile/.lock early, so the bundle install step can be run early and cached
ADD Gemfile /home/app/disease-trakker/Gemfile
ADD Gemfile.lock /home/app/disease-trakker/Gemfile.lock

RUN chown -R app:app .

RUN su app -c 'bundle install --binstubs --without development test'

RUN yarn config set cafile /etc/ssl/certs/ca-certificates.crt
RUN yarn install

ADD . /home/app/disease-trakker

# Create a folder that needs to exist for the precompile
RUN mkdir -p ./app/assets/stylesheets
# SECRET_KEY_BASE sets a dummy secret key, so that the precompiler (which doesn't need the secret key for anything) can run
RUN SECRET_KEY_BASE=precompile_only bundle exec rake assets:precompile

RUN bundle exec whenever --update-crontab

CMD bundle exec rails s puma -C config/puma.rb

EXPOSE 3000
