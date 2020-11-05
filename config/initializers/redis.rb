# Redis.new will use ENV['REDIS_URL'] to connect to.
Rails.application.configure do
  config.redis = Redis.new
end
