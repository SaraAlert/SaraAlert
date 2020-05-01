# frozen_string_literal: true

# PurgeJob: purges after a set period of time
class PurgeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Patient.purge_eligible.find_each(batch_size: 5000) do |monitoree|
      # Whitelist attributes to keep
      attributes = Patient.new.attributes.keys
      whitelist = %w[id created_at updated_at responder_id creator_id jurisdiction_id
                     submission_token monitoring monitoring_reason exposure_risk_assessment
                     monitoring_plan isolation symptom_onset public_health_action age sex
                     address_county symptom_onset contact_of_known_case
                     member_of_a_common_exposure_cohort travel_to_affected_country_or_area
                     laboratory_personnel was_in_health_care_facility_with_known_cases
                     healthcare_personnel crew_on_passenger_or_cargo_flight]
      attributes -= whitelist
      mask = Hash[attributes.collect { |a| [a, nil] }].symbolize_keys
      mask[:monitoring] = false
      monitoree.update!(mask)
      monitoree.purged = true
      monitoree.save!
      History.where(patient_id: monitoree.id).delete_all
    end
  end
end
