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

  def perform_batch(patient_batch, monitoring_reason, completed_message: false)
    patient_batch_ids = patient_batch.pluck(:id)
    return { closed: [], not_closed: [], count: 0 } if patient_batch_ids.empty?

    closed = []
    not_closed = []

    ActiveRecord::Base.transaction do
      # Close records
      patient_batch.update_all(
        monitoring: false,
        closed_at: DateTime.now,
        updated_at: DateTime.now,
        monitoring_reason: monitoring_reason,
        continuous_exposure: false
      )
      # Create histories
      History.import(
        patient_batch_ids.map { |pid| History.record_automatically_closed(patient: pid, create: false) },
        validate: false
      )
      # Update closed variable
      closed = patient_batch_ids.map { |pid| { id: pid } }
    rescue StandardError => e
      not_closed = patient_batch_ids.map { |pid| { id: pid, reason: e.message } }
    end

    # Send emails to patients with an email in the system
    if completed_message
      patient_batch_ids.each_slice(10_000) do |ids|
        Patient.where(id: ids)
               .where('patients.id = patients.responder_id')
               .where('patients.email IS NOT NULL AND patients.email != \'\'')
               .select(:id)
               .each do |patient|
          PatientMailer.closed_email(patient).deliver_later
        rescue StandardError => _e
          next
        end
      end
    end

    {
      closed: closed,
      not_closed: not_closed,
      count: closed.size + not_closed.size
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
