# frozen_string_literal: true

# ClosePatientsJob: closes patient records based on criteria
class ClosePatientsJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    # This preloads all jurisdiction send_close so that they can be fetched
    # quickly while the job is iterating through patients.
    juris_send_close = Jurisdiction.pluck(:id, :send_close).to_h

    # Gather patients in groups of criteria
    enrolled_past_monitioring_period = Patient.close_eligible(:enrolled_past_monitioring_period)
    enrolled_last_day_monitoring_period = Patient.close_eligible(:enrolled_last_day_monitoring_period)
    no_recent_activity = Patient.close_eligible(:no_recent_activity)
    completed_monitoring = Patient.close_eligible(:completed_monitoring)
    # Close patients using the scopes that have not been executed yet.
    monitoring_period = ADMIN_OPTIONS['monitoring_period_days']
    results = combine_batch_results(
      [
        perform_batch(enrolled_past_monitioring_period, "Enrolled more than #{monitoring_period} days after last date of exposure (system)", juris_send_close),
        perform_batch(enrolled_last_day_monitoring_period, 'Enrolled on last day of monitoring period (system)', juris_send_close),
        perform_batch(no_recent_activity, 'No record activity for 30 days (system)', juris_send_close),
        perform_batch(completed_monitoring, 'Completed Monitoring (system)', juris_send_close, completed_message: true)
      ]
    )

    # Send results
    UserMailer.close_job_email(results[:closed], results[:not_closed], results[:count]).deliver_now
  end

  def perform_batch(patients, monitoring_reason, jurisdiction_send_close, completed_message: false)
    closed = []
    not_closed = []
    histories = []

    # Close patients who are past the monitoring period (and are actually closable from above logic)
    patients.find_in_batches(batch_size: 15_000).each do |group|
      group.each do |patient|
        # Update related fields
        patient[:monitoring] = false
        patient[:closed_at] = DateTime.now
        patient[:monitoring_reason] = monitoring_reason
        patient.save!

        # Send closed notification to patient if they are a reporter, the closure reason warrants a close
        # notification, and if the jurisdiction has opted-in to closed notifications.
        #
        # If 'sms texted weblink' or 'sms text-message' is preferred, then an SMS will be sent
        # If 'e-mailed web link' is preferred, then an email will be sent
        # If the preferred contact method is not supported for close notifications, then a history item will
        # be created stating so.
        #
        # We are checking some of the same crieria here as in the patient mailer for closed messages.
        # This is intentionally done to avoid enqueuing mail that is "destined to fail", as well as to cover the case
        # where the patient record is modified between being enqueued and the mailer job actually being executed.
        if completed_message && patient.self_reporter_or_proxy? && jurisdiction_send_close[patient.jurisdiction_id]
          contact_method = patient.preferred_contact_method&.downcase
          if ['sms texted weblink', 'sms text-message'].include? contact_method
            # Do not enqueue if the contact method is blank or if SMS is blocked
            if patient.blocked_sms
              histories << History.send_close_sms_blocked(patient: patient, create: false)
            elsif patient.primary_telephone.blank?
              histories << History.send_close_conact_method_blank(patient: patient, type: 'primary phone number', create: false)
            else
              PatientMailer.closed_sms(patient).deliver_later(wait_until: patient.time_to_notify_closed)
            end
          elsif contact_method == 'e-mailed web link'
            # Do not enqueue if the contact method is blank
            if patient.email.blank?
              histories << History.send_close_conact_method_blank(patient: patient, type: 'email', create: false)
            else
              PatientMailer.closed_email(patient).deliver_later(wait_until: patient.time_to_notify_closed)
            end
          else
            history_friendly_method = patient.preferred_contact_method.blank? ? patient.preferred_contact_method : 'Unknown'
            histories << History.monitoring_complete_message_sent(
              patient: patient,
              comment: 'The system was unable to send a monitoring complete message to this monitoree because their'\
                       "preferred contact method, #{history_friendly_method}, is not supported for this message type.",
              create: false
            )
          end
        end

        # History item for automatically closing the record
        histories << History.record_automatically_closed(patient: patient, reason: monitoring_reason, create: false)

        closed << { id: patient.id }
      rescue StandardError => e
        not_closed << { id: patient.id, reason: e.message }
        next
      end
    end

    History.import! histories

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
