# frozen_string_literal: true

# ClosePatientsJob: closes patient records based on criteria
class ClosePatientsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Grab closable patients
    eligible = Patient.close_eligible

    closed = []
    not_closed = []

    # Close patients who are past the monitoring period (and are actually closable from above logic)
    eligible.each do |patient|
      # Update related fields
      patient[:monitoring] = false
      patient[:closed_at] = DateTime.now

      # If the patient was enrolled already past their monitoring period based on their last date of exposure, specify special reason for closure
      if !patient.last_date_of_exposure.nil? &&
         ((patient.last_date_of_exposure.beginning_of_day + ADMIN_OPTIONS['monitoring_period_days'].days) < patient.created_at.beginning_of_day)
        patient[:monitoring_reason] = 'Enrolled more than 14 days after last date of exposure (system)'
      elsif !patient.last_date_of_exposure.nil? &&
            ((patient.last_date_of_exposure.beginning_of_day + ADMIN_OPTIONS['monitoring_period_days'].days) == patient.created_at.beginning_of_day)
        # If the patient was enrolled on their last day of monitoring based on their last date of exposure, specify special reason for closure
        patient[:monitoring_reason] = 'Enrolled on last day of monitoring period (system)'
      else
        # Otherwise, normal reason for closure
        patient[:monitoring_reason] = 'Completed Monitoring (system)'
      end

      # Send closed email to patient if they are a reporter
      PatientMailer.closed_email(patient).deliver_later if patient.save! && patient.email.present? && patient.self_reporter_or_proxy?

      # History item for automatically closing the record
      History.record_automatically_closed(patient: patient)

      closed << { id: patient.id }
    rescue StandardError => e
      not_closed << { id: patient.id, reason: e.message }
      next
    end

    # Send results
    UserMailer.close_job_email(closed, not_closed, eligible.size).deliver_now
  end
end
