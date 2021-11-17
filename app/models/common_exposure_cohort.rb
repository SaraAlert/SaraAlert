# frozen_string_literal: true

# CommonExposureCohort: a common exposure cohort
class CommonExposureCohort < ApplicationRecord
  belongs_to :patient, touch: true

  VALID_COHORT_TYPES = [nil, '', 'Adult Congregate Living Facility', 'Child Care Facility', 'Community Event or Mass Gathering', 'Correctional Facility',
                        'Group Home', 'Healthcare Facility', 'Place of Worship', 'School or University', 'Shelter', 'Substance Abuse Treatment Center',
                        'Workplace', 'Other'].freeze

  validates :cohort_type, length: { maximum: 200 }, inclusion: {
    in: VALID_COHORT_TYPES,
    message: "is not an acceptable value, acceptable values are: '#{VALID_COHORT_TYPES.reject(&:blank?).join("', '")}'"
  }

  validates :cohort_name, length: { maximum: 200 }
  validates :cohort_location, length: { maximum: 200 }

  validate :validate_cohort_fields_present?

  def validate_cohort_fields_present?
    return if cohort_type.present? || cohort_name.present? || cohort_location.present?

    errors.add :base, 'Cohort type, name, or location must be present'
  end
end
