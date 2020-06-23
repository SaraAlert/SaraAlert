# Jobs that fail during execution will only retry this many times, default is 25
# Accordinig to sidekiq docs 25 retries will take 3 weeks to complete
Sidekiq.options[:max_retries] = 2