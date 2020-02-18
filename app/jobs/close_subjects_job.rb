class CloseSubjectsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Iterate over all subjects that could be closeable based on the time they were enrolled
    closeable = Patient.where("created_at < ? ", Date.today - ADMIN_OPTIONS['monitoring_period_days'].days)
    closeable.each do |subject|
      # TODO Add additional criteria for cases that we can auto-close eg: Non-symptomatic
      subject[:monitoring] = false
      subject.save!
    end
  end
end
