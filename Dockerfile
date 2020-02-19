# Pinned to the latest ruby 2.6.0 version of the Passenger base Docker image
FROM phusion/passenger-ruby26:1.0.6

# Install the MITRE certificates into Ubuntu, to prevent self-signed certificate issues
RUN curl -o /usr/local/share/ca-certificates/MITRE-BA-Root.crt http://pki.mitre.org/MITRE%20BA%20Root.crt
RUN curl -o /usr/local/share/ca-certificates/MITRE-BA-NPE-CA-3.crt "http://pki.mitre.org/MITRE%20BA%20NPE%20CA-3(1).crt"
RUN update-ca-certificates

# Install node, tzdata, and yarn
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - 
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

ADD . /home/app/disease-trakker

# Set yarn 
RUN yarn config set cafile /usr/local/share/ca-certificates/MITRE-BA-Root.crt
RUN npm config set cafile /usr/local/share/ca-certificates/MITRE-BA-Root.crt

# Create a folder that needs to exist for the precompile
RUN mkdir -p ./app/assets/stylesheets
# SECRET_KEY_BASE sets a dummy secret key, so that the precompiler (which doesn't need the secret key for anything) can run
RUN SECRET_KEY_BASE=precompile_only bundle exec rake assets:precompile

CMD bundle exec rails s puma -C config/puma.rb

EXPOSE 3000
