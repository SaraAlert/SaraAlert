# frozen_string_literal: true

# Validates that the number of associated records does not exceed predefined limits
class AssociatedRecordLimitValidator < ActiveModel::Validator
  include ValidationHelper

  COMMON_EXPOSURE_COHORTS_MAX = 10

  def validate(record)
    return unless record.common_exposure_cohorts.size > COMMON_EXPOSURE_COHORTS_MAX

    record.errors.add(:base, "Patient cannot have more than #{COMMON_EXPOSURE_COHORTS_MAX} common exposure cohorts")
  end
end
