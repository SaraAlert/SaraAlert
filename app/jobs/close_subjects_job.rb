class CloseSubjectsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Iterate over all subjects that could be closeable based on the time they were enrolled

    # Closable if:
    #   - Subject's last exposure (or created_at) + <monitoring_period_days> has passed
    #     AND
    #   - Subject's last assessment was not symptomatic
    #     AND
    #   - Subject's last assessment was completed within the <reporting_period_minutes>

    # Grab closable subjects (similar logic to public_health_controller)
    # TODO: Performance enhancements should be made when this logic solidifies
    patients = Patient.where(monitoring: true).includes(:latest_assessment)
    time_boundary = ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago
    non_reporting_patients = patients.reject do |p|
      (p.created_at >= time_boundary || # Created more recently than our time boundary, so not expected to have reported yet
       p.latest_assessment&.symptomatic || # Symptomatic, handled in a different list
       (p.latest_assessment && p.latest_assessment.created_at >= time_boundary)) # Reported recently
    end
    symptomatic_patients = patients.select { |p| p.latest_assessment&.symptomatic }
    closeable = patients - (non_reporting_patients + symptomatic_patients)

    # Close subjects who are past the monitoring period (and are actually closable from above logic)
    closeable.each do |subject|
        if !subject.last_date_of_exposure.nil? && subject.last_date_of_exposure < ADMIN_OPTIONS['monitoring_period_days'].days.ago
          subject[:monitoring] = false
          subject.save!
        elsif subject.created_at < ADMIN_OPTIONS['monitoring_period_days'].days.ago
          subject[:monitoring] = false
          subject.save!
        end
    end
  end
end
