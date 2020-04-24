# For information about how to use this file see https://github.com/javan/whenever

set :output, "/tmp/cronlog.log"

every 24.hours do
  runner "CloseSubjectsJob.perform_now"
end

every :sunday do
  runner "PurgeJob.perform_now"
end

every 1.hours do
  runner "CacheAnalyticsJob.perform_now"
end

every 1.hours do
  runner "SendAssessmentsJob.perform_now"
end
