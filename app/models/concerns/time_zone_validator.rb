# frozen_string_literal: true

# Validates that a given date (attribute) is valid
class TimeZoneValidator < ActiveModel::Validator
  def validate(record)
    return unless Time.find_zone(record.time_zone).nil?

    record.errors.add(:time_zone, 'invalid time_zone')
  end
end
