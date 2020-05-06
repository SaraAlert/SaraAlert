Raven.configure do |config|
  config.dsn = ADMIN_OPTIONS['sentry_url']
  config.release = ADMIN_OPTIONS['version']
end
