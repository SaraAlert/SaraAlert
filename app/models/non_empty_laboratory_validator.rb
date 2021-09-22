# frozen_string_literal: true

# Validates that the laboratory model has at least one field present
class NonEmptyLaboratoryValidator < ActiveModel::Validator
  include ValidationHelper

  def validate(record)
    return if %i[lab_type specimen_collection report result].any? { |field| record[field].present? }

    field_labels = %i[lab_type specimen_collection report result].map { |field| "'#{VALIDATION[field][:label]}'" }.join(', ')
    record.errors.add(:base, "At least one of #{field_labels} must be present")
  end
end
