FROM ruby:2.6.6-alpine

ARG cert

RUN echo "${cert}" > /usr/local/share/ca-certificates/ca-certificates.crt
RUN update-ca-certificates

RUN apk --update add nodejs yarn mariadb-dev tzdata
RUN apk --update add --virtual build-dependencies make g++ patch npm

RUN yarn config set cafile /etc/ssl/certs/ca-certificates.crt
RUN npm install node-gyp -g

RUN mkdir -p /app/disease-trakker
RUN mkdir -p /app/disease-trakker/app/assets/stylesheets

COPY Gemfile Gemfile.lock /app/disease-trakker/
WORKDIR /app/disease-trakker
RUN gem install bundler -v 2.1.4 && bundle config set without 'development test' && bundle config set deployment 'true'
RUN bundle install --jobs $(nproc)
RUN yarn install --no-optional

RUN addgroup -g 1000 -S app && adduser -u 1000 -S app -G app
COPY . /app/disease-trakker
RUN RAILS_ENV=production SECRET_KEY_BASE=precompile_only bundle exec rake assets:precompile

RUN apk del build-dependencies && \
    find /usr/local/bundle/gems/ -name "*.c" -delete && \
    rm -rf /usr/local/bundle/cache/*.gem /var/cache/apk/* node_modules tmp/ /tmp vendor/assets test/ /root/.bundle /root/.npm /usr/local/share/.cache
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
