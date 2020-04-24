# frozen_string_literal: true

# PurgeJob: purges after a set period of time
class PurgeJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    Patient.purge_eligible.find_each(batch_size: 5000) do |monitoree|
      # Whitelist attributes to keep
      attributes = Patient.new.attributes.keys
      whitelist = %w[id created_at updated_at responder_id creator_id jurisdiction_id
                     submission_token monitoring_reason exposure_risk_assessment monitoring_plan
                     public_health_action age sex]
      attributes -= whitelist
      mask = Hash[attributes.collect { |a| [a, nil] }].symbolize_keys
      mask[:monitoring] = false
      monitoree.update!(mask)
      monitoree.purged = true
      monitoree.save!
    end
  end
end
