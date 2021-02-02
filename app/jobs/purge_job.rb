# frozen_string_literal: true

# PurgeJob: purges after a set period of time
class PurgeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    eligible = Patient.purge_eligible
    purged = []
    not_purged = []
    eligible_count = eligible.count

    # Loop through and purge
    eligible.find_each do |monitoree|
      next if monitoree.active_dependents.count.positive?

      monitoree.laboratories.destroy_all
      monitoree.close_contacts.destroy_all
      monitoree.histories.destroy_all
      monitoree.contact_attempts.destroy_all

      attributes = Patient.new.attributes.keys
      attributes -= PurgeJob.attributes_to_keep
      # Set everything else to nil
      mask = Hash[attributes.collect { |a| [a, nil] }].symbolize_keys
      mask[:purged] = true
      monitoree.update!(mask)
      purged << { id: monitoree.id }
    rescue StandardError => e
      not_purged << { id: monitoree.id, reason: e.message }
      next
    end

    # Additional cleanup
    Download.where('created_at < ?', 24.hours.ago).delete_all
    AssessmentReceipt.where('created_at < ?', 24.hours.ago).delete_all
    Symptom.where(condition_id: ReportedCondition.where(assessment_id: Assessment.where(patient_id: Patient.where(purged: true).ids).ids).ids).delete_all
    ReportedCondition.where(assessment_id: Assessment.where(patient_id: Patient.where(purged: true).ids).ids).delete_all
    Assessment.where(patient_id: Patient.where(purged: true).ids).delete_all

    # Send results
    UserMailer.purge_job_email(purged, not_purged, eligible_count).deliver_now
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
       native_hawaiian_or_other_pacific_islander ethnicity purged
       continuous_exposure time_zone]
  end
end
