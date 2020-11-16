# frozen_string_literal: true

# Validates dates on the Laboratory model
class LaboratoryDateValidator < ActiveModel::Validator
  include ValidationHelper

  def validate(record)
    year_start = Date.new(2020, 1, 1)
    validate_between_dates(record, :report, year_start, Time.now.to_date) if record.report_changed?
    validate_between_dates(record, :specimen_collection, year_start, Time.now.to_date) if record.specimen_collection_changed?
  end
end
