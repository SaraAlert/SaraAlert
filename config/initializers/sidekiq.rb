# Jobs that fail during execution will only retry this many times, default is 25
# According to sidekiq docs 25 retries will take 3 weeks to complete
Sidekiq.options[:max_retries] = 5

Sidekiq.configure_server do |config|
  # Set the network timeout to be 5 seconds instead of the default 1 to help with
  # cloud network latency and longer batch commands
  config.redis = { url: ENV['REDIS_URL'], network_timeout: 5 }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'], network_timeout: 5 }
end
