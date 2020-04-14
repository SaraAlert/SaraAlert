FROM ruby:2.6.6-alpine

ARG cert

RUN echo "${cert}" > /usr/local/share/ca-certificates/ca-certificates.crt
RUN update-ca-certificates

RUN apk --update add nodejs yarn mariadb-dev tzdata
RUN apk --update add --virtual build-dependencies make g++

RUN yarn config set cafile /etc/ssl/certs/ca-certificates.crt

RUN mkdir -p /app/disease-trakker
RUN mkdir -p /app/disease-trakker/app/assets/stylesheets

COPY Gemfile Gemfile.lock /app/disease-trakker/
WORKDIR /app/disease-trakker
RUN gem install bundler && bundle config set without 'development test' && bundle config set deployment 'true'
RUN bundle install --jobs $(nproc)
RUN yarn install
RUN apk del build-dependencies && rm -rf /var/cache/apk/* && rm -rf /usr/local/bundle/cache/*.gem && find /usr/local/bundle/gems/ -name "*.c" -delete

RUN addgroup -g 1000 -S app && adduser -u 1000 -S app -G app
COPY . /app/disease-trakker

RUN yarn global add node-gyp
RUN yarn install --no-optional
RUN RAILS_ENV=production SECRET_KEY_BASE=precompile_only bundle exec rake assets:precompile
RUN rm -rf node_modules tmp/ vendor/assets lib/assets test/
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_ENV production

COPY docker-entrypoint.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN chown app:app /usr/local/bundle/config
RUN chown -R app:app /app/disease-trakker
USER app

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
