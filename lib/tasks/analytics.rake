require 'active_support'

namespace :analytics do

  desc "Cache Current Analytics"
  task cache_current_analytics: :environment do
    CacheAnalyticsJob.perform_later
  end
end
