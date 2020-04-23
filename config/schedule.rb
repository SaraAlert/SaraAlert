# For information about how to use this file see https://github.com/javan/whenever

set :output, "/tmp/cronlog.log"

every 24.hours do
  runner "CloseSubjectsJob.perform_now"
end

every ADMIN_OPTIONS['weekly_purge_date'] do
  runner "PurgeJob.perform_now"
end

every 1.hours do
  runner "CacheAnalyticsJob.perform_now"
end

every ADMIN_OPTIONS['weekly_purge_warning_date'] do
  rake "mailers:send_purge_warning"
end

every 30.minutes do
  rake "analytics:cache_current_analytics"
end

every 1.hours do
  runner "SendAssessmentsJob.perform_now"
end
