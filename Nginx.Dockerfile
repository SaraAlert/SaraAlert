# Base image:
ARG sara_alert_image
FROM ${sara_alert_image} as base
FROM nginx:latest


# Install dependencies
RUN apt-get update -qq && apt-get -y install apache2-utils

# establish where Nginx should look for files
ENV RAILS_ROOT /var/www/saraalert

# Set our working directory inside the image
WORKDIR $RAILS_ROOT

# create log directory
RUN mkdir log

# copy over static assets
COPY --from=base /app/disease-trakker/public public/

EXPOSE 80
EXPOSE 443

# Use the "exec" form of CMD so Nginx shuts down gracefully on SIGTERM (i.e. `docker stop`)
CMD [ "nginx", "-g", "daemon off;" ]
