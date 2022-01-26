# frozen_string_literal: true

# Validates dates on the Patient model
class PatientDateValidator < ActiveModel::Validator
  include ValidationHelper

  def validate(record)
    year_start = Date.new(2020, 1, 1)
    # NOTE: Commented out for rubocop until other validations are uncommented
    # month_ahead = 30.days.from_now.to_date
    # month_behind = 30.days.ago.to_date
    # This is to handle the edge case when certain time zones such as Samoa are on the new day before UTC
    earliest_tz_today = Time.now.in_time_zone(ActiveSupport::TimeZone.all.last).to_date
    validate_between_dates(record, :symptom_onset, year_start, earliest_tz_today) if record.symptom_onset_changed?

    # NOTE: Commented out until additional testing
    # validate_between_dates(record, :date_of_birth, Date.new(1900, 1, 1), earliest_tz_today) if record.date_of_birth_changed?
    # validate_between_dates(record, :last_date_of_exposure, year_start, month_ahead) if record.last_date_of_exposure_changed?
    # validate_between_dates(record, :extended_isolation, month_behind, month_ahead) if record.extended_isolation_changed?
    # validate_between_dates(record, :date_of_departure, year_start, earliest_tz_today) if record.date_of_departure_changed?
    # validate_between_dates(record, :date_of_arrival, year_start, month_ahead) if record.date_of_arrival_changed?
    # validate_between_dates(record, :additional_planned_travel_start_date, year_start, month_ahead) if record.additional_planned_travel_start_date_changed?
    # validate_between_dates(record, :additional_planned_travel_end_date, year_start, month_ahead) if record.additional_planned_travel_end_date_changed?
  end
end
