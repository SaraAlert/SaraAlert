# frozen_string_literal: true

# Validates dates on the Laboratory model
class LaboratoryDateValidator < ActiveModel::Validator
  include ValidationHelper

  # Time.zone is set by Rails.application.config.time_zone which defaults to UTC.
  # Therefore, Time.zone.today makes UTC explicit and is consistient with previous behavior.
  def validate(record)
    year_start = Date.new(2020, 1, 1)
    validate_between_dates(record, :report, year_start, Time.zone.today) if record.report_changed?
    validate_between_dates(record, :specimen_collection, year_start, Time.zone.today) if record.specimen_collection_changed?
    return unless record.report && record.specimen_collection && (record.specimen_collection > record.report)

    record.errors.add(:report, 'cannot be before Specimen Collection Date.')
  end
end
