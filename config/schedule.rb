# For information about how to use this file see https://github.com/javan/whenever

# Load rails environment to provide application control/knowledge of job timings
require File.expand_path(File.dirname(__FILE__) + "/environment")

set :output, "/tmp/cronlog.log"

every 24.hours do
  runner "CloseSubjectsJob.perform_now"
end

weekly_purge_date = Chronic.parse(ADMIN_OPTIONS['weekly_purge_date'])
every weekly_purge_date.strftime("%A"), at: weekly_purge_date.strftime("%I:%M %p") do
  runner "PurgeJob.perform_now"
end

weekly_purge_warning_date = Chronic.parse(ADMIN_OPTIONS['weekly_purge_warning_date'])
every weekly_purge_warning_date.strftime("%A"), at: weekly_purge_warning_date.strftime("%I:%M %p") do
  rake "mailers:send_purge_warning  RAILS_ENV=development"
end

every 1.hours do
  runner "CacheAnalyticsJob.perform_now"
end

every 30.minutes do
  rake "analytics:cache_current_analytics"
end

every 1.hours do
  runner "SendAssessmentsJob.perform_now"
end
