# frozen_string_literal: true

# PurgeJob: purges after a set period of time
class PurgeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    Patient.purge_eligible.find_each(batch_size: 5000) do |monitoree|
      next if monitoree.dependents.where.not(id: monitoree.id).where(monitoring: true).count.positive?

      # Delete Twilio data
      client = Twilio::REST::Client.new(account_sid, auth_token)
      messages = client.messages.list(to: Phonelib.parse(patient.primary_telephone, 'US').full_e164)
      messages.each do |record|
        record.delete
      end

      # Whitelist attributes to keep
      attributes = Patient.new.attributes.keys
      whitelist = %w[id created_at updated_at responder_id creator_id jurisdiction_id
                     submission_token monitoring monitoring_reason exposure_risk_assessment
                     monitoring_plan isolation symptom_onset public_health_action age sex
                     address_county symptom_onset contact_of_known_case
                     member_of_a_common_exposure_cohort travel_to_affected_country_or_area
                     laboratory_personnel was_in_health_care_facility_with_known_cases
                     healthcare_personnel crew_on_passenger_or_cargo_flight white
                     black_or_african_american american_indian_or_alaska_native asian
                     native_hawaiian_or_other_pacific_islander ethnicity]
      attributes -= whitelist
      mask = Hash[attributes.collect { |a| [a, nil] }].symbolize_keys
      mask[:monitoring] = false
      monitoree.update!(mask)
      monitoree.purged = true
      monitoree.save!
      monitoree.histories.destroy_all
    end
    Download.where('created_at < ?', 24.hours.ago).destroy_all
  end
end
