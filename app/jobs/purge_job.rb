# frozen_string_literal: true

# PurgeJob: purges after a set period of time
class PurgeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    job_info = {
      start_time: DateTime.now
    }
    eligible = Patient.purge_eligible
    purged = []
    not_purged = []
    job_info[:eligible] = eligible.count

    # Loop through and purge
    eligible.find_each do |monitoree|
      next if monitoree.active_dependents.count.positive?

      monitoree.laboratories.destroy_all
      monitoree.close_contacts.destroy_all
      monitoree.histories.destroy_all
      monitoree.contact_attempts.destroy_all
      monitoree.vaccines.destroy_all

      attributes = Patient.new.attributes.keys
      attributes -= PurgeJob.attributes_to_keep
      # Set everything else to nil
      mask = attributes.collect { |a| [a, nil] }.to_h.symbolize_keys
      mask[:purged] = true
      monitoree.update!(mask)
      monitoree.responder.refresh_head_of_household if monitoree.responder_id != monitoree.id
      purged << { id: monitoree.id }
    rescue StandardError => e
      not_purged << { id: monitoree.id, reason: e.message }
      next
    end

    # Additional cleanup
    # Destroy all must be called on the downloads because the after destroy callback must be executed to remove the blobs from object storage
    Download.where('created_at < ?', 24.hours.ago).destroy_all
    ApiDownload.where('created_at < ?', 24.hours.ago).destroy_all
    AssessmentReceipt.where('created_at < ?', 24.hours.ago).delete_all
    Symptom.where(condition_id: ReportedCondition.where(assessment_id: Assessment.where(patient_id: Patient.where(purged: true).ids).ids).ids).delete_all
    ReportedCondition.where(assessment_id: Assessment.where(patient_id: Patient.where(purged: true).ids).ids).delete_all
    Assessment.where(patient_id: Patient.where(purged: true).ids).delete_all

    # Gather statistics
    job_info[:end_time] = DateTime.now
    job_info[:not_purged_count] = not_purged.length
    job_info[:purged_count] = purged.length
    total_purged_emails_to_send = calculate_total_emails(job_info[:not_purged_count] + job_info[:purged_count])

    # in_groups_of will not perform an iteration if the array is empty.
    if (job_info[:not_purged_count] + job_info[:purged_count]).zero?
      UserMailer.purge_job_email([], { current: 1, total: total_purged_emails_to_send }, job_info).deliver_later
    else
      # Send results in batches to avoid emails that are too large to send
      (purged | not_purged).in_groups_of(ADMIN_OPTIONS['job_run_email_group_size'].to_i, false).each_with_index do |group, index|
        UserMailer.purge_job_email(group, { current: index + 1, total: total_purged_emails_to_send }, job_info).deliver_later
      end
    end
  end

  # Everything except these will be set to nil
  def self.attributes_to_keep
    %w[id created_at updated_at responder_id creator_id jurisdiction_id
       monitoring monitoring_reason exposure_risk_assessment
       monitoring_plan isolation symptom_onset public_health_action age sex
       address_county symptom_onset contact_of_known_case
       member_of_a_common_exposure_cohort travel_to_affected_country_or_area
       laboratory_personnel was_in_health_care_facility_with_known_cases
       healthcare_personnel crew_on_passenger_or_cargo_flight white
       black_or_african_american american_indian_or_alaska_native asian
       native_hawaiian_or_other_pacific_islander race_other race_unknown
       race_refused_to_answer ethnicity purged continuous_exposure time_zone]
  end

  private

  def calculate_total_emails(total_monitorees)
    total_emails = (total_monitorees.to_f / ADMIN_OPTIONS['job_run_email_group_size'].to_i).ceil
    [1, total_emails].max
  end
end
