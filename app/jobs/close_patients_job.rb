# frozen_string_literal: true

# ClosePatientsJob: closes patient records based on criteria
class ClosePatientsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # Close patients in groups of criteria
    results = combine_batch_results(
      [
        perform_batch(Patient.close_eligible(:enrolled_past_monitioring_period), 'Enrolled more than 14 days after last date of exposure (system)'),
        perform_batch(Patient.close_eligible(:enrolled_last_day_monitoring_period), 'Enrolled on last day of monitoring period (system)'),
        perform_batch(Patient.close_eligible(:no_recent_activity), 'No record activity for 30 days (system)'),
        perform_batch(Patient.close_eligible(:completed_monitoring), 'Completed Monitoring (system)', completed_message: true)
      ]
    )

    # Send results
    UserMailer.close_job_email(results[:closed], results[:not_closed], results[:count]).deliver_now
  end

  def perform_batch(patients, monitoring_reason, completed_message: false)
    closed = []
    not_closed = []
    count = 0

    # Close patients who are past the monitoring period (and are actually closable from above logic)
    patients.each do |patient|
      count += 1
      # Update related fields
      patient[:monitoring] = false
      patient[:closed_at] = DateTime.now
      patient[:monitoring_reason] = monitoring_reason
      patient.save!

      # Send closed email to patient if they are a reporter
      PatientMailer.closed_email(patient).deliver_later if completed_message && patient.email.present? && patient.self_reporter_or_proxy?

      # History item for automatically closing the record
      History.record_automatically_closed(patient: patient)

      closed << { id: patient.id }
    rescue StandardError => e
      not_closed << { id: patient.id, reason: e.message }
      next
    end

    {
      closed: closed,
      not_closed: not_closed,
      count: count
    }
  end

  def combine_batch_results(batch_results)
    # Expected blank results
    results = {
      closed: [],
      not_closed: [],
      count: 0
    }
    # Combine the results
    batch_results.each do |batch_result|
      results[:closed] += batch_result[:closed]
      results[:not_closed] += batch_result[:not_closed]
      results[:count] += batch_result[:count]
    end
    results
  end
end
