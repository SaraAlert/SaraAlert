# frozen_string_literal: true

# CloseSubjectsJob: closes subject monitoring based on criteria
class CloseSubjectsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Iterate over all subjects that could be closeable based on the time they were enrolled

    # Closable if:
    #   - Subject's last exposure (or created_at) + <monitoring_period_days> has passed
    #     AND
    #   - Subject is not symptomatic
    #     AND
    #   - Subject's last assessment was completed within the <reporting_period_minutes>

    # Grab closable subjects
    closeable = Patient.exposure_asymptomatic.where(continuous_exposure: false)

    # Close subjects who are past the monitoring period (and are actually closable from above logic)
    closeable.find_each(batch_size: 5000) do |subject|
      if (!subject.last_date_of_exposure.nil? && subject.last_date_of_exposure <= (ADMIN_OPTIONS['monitoring_period_days'] + 1).days.ago) ||
         (subject.last_date_of_exposure.nil? && subject.created_at < (ADMIN_OPTIONS['monitoring_period_days'] + 1).days.ago)
        subject[:monitoring] = false
        subject.closed_at = DateTime.now
        subject[:monitoring_reason] = 'Past monitoring period'
        if subject.save! && subject.email.present?
          PatientMailer.closed_email(subject).deliver_later if subject.self_reporter_or_proxy?
        end
        History.record_automatically_closed(patient: subject)
      end
    end
  end
end
