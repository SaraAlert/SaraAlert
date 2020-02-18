# For information about how to use this file see https://github.com/javan/whenever


set :output, "/tmp/cronlog.log"


############# Development Settings For Development And Demonstration ############

every 1.hour do
  runner "CloseSubjectsJob.perform_now", :environment => "development"
end

#################################################################################



########################### Production Settings #################################

# every 24.hours do
#     runner "CloseSubjectsJob.perform_now"
# end

#################################################################################