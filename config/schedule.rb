# For information about how to use this file see https://github.com/javan/whenever

set :output, "/tmp/cronlog.log"

every 4.hours do
  runner "CloseSubjectsJob.perform_now"
end

every 24.hours do
  runner "PurgeJob.perform_now"
end

every 30.minutes do
  "rake analytics:cache_current_analytics"
end

every 1.hours do
  "rake mailers:send_assessments"
end
