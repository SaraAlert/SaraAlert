# frozen_string_literal: true

# Validates that when in Isolation, either:
# - symptom_onset is set to a value
# - the patient has at least one positive lab result
class IsolationSymptomOnsetValidator < ActiveModel::Validator
  include ValidationHelper
  def validate(record)
    return unless record.isolation &&
                  record.symptom_onset.nil? &&
                  record.laboratories.find { |lab| lab.result == 'positive' && lab.specimen_collection.present? }.nil?

    record.errors.add(:base,
                      "Either a #{VALIDATION[:symptom_onset][:label]} or a Positive Lab with a known"\
                      " Specimen Collection Date is required when Isolation is 'true'")
  end
end
