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
    eligible = Patient.exposure_asymptomatic.where(continuous_exposure: false)

    closed = []
    not_closed = []
    eligible_count = eligible.count

    # Close subjects who are past the monitoring period (and are actually closable from above logic)
    eligible.find_each do |subject|
      if (!subject.last_date_of_exposure.nil? && subject.last_date_of_exposure <= (ADMIN_OPTIONS['monitoring_period_days']).days.ago.beginning_of_day) ||
         (subject.last_date_of_exposure.nil? && subject.created_at <= (ADMIN_OPTIONS['monitoring_period_days']).days.ago.beginning_of_day)
        begin
          subject[:monitoring] = false
          subject.closed_at = DateTime.now
          subject[:monitoring_reason] = 'Past monitoring period'
          if subject.save! && subject.email.present?
            PatientMailer.closed_email(subject).deliver_later if subject.self_reporter_or_proxy?
          end
          History.record_automatically_closed(patient: subject)
          closed << { id: subject.id }
        rescue StandardError => e
          not_closed << { id: subject.id, reason: e.message }
          next
        end
      end
    end

    # Send results
    UserMailer.close_job_email(closed, not_closed, eligible_count).deliver_now
  end
end
