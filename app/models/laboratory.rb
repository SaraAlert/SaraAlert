# frozen_string_literal: true

# Laboratory: represents a lab result
class Laboratory < ApplicationRecord
  include ValidationHelper

  belongs_to :patient, touch: true

  validates :result, inclusion: { in: ['positive', 'negative', 'indeterminate', 'other', nil, ''] }

  validates :lab_type, on: %i[api import], inclusion: {
    in: VALID_PATIENT_ENUMS[:lab_type],
    message: "is not an acceptable value, acceptable values are: '#{VALID_PATIENT_ENUMS[:lab_type].reject(&:blank?).join("', '")}'"
  }

  %i[specimen_collection
     report].each do |date_field|
    validates date_field, on: %i[api import], date: true
  end

  # NOTE: Commented out until additional testing
  # validates_with LaboratoryDateValidator

  after_save :update_patient_linelist_after_save
  before_destroy :update_patient_linelist_before_destroy

  # Returns a representative FHIR::Observation for an instance of a Sara Alert Laboratory.
  # https://www.hl7.org/fhir/observation.html
  def as_fhir
    FHIR::Observation.new(
      meta: FHIR::Meta.new(lastUpdated: updated_at.strftime('%FT%T%:z')),
      id: id,
      subject: FHIR::Reference.new(reference: "Patient/#{patient_id}"),
      status: 'final',
      effectiveDateTime: report.strftime('%FT%T%:z'),
      valueString: result
    )
  end

  private

  def update_patient_linelist_after_save
    patient.update(
      first_positive_lab_at: patient.laboratories.where(result: 'positive').minimum(:specimen_collection),
      negative_lab_count: patient.laboratories.where(result: 'negative').size
    )
  end

  def update_patient_linelist_before_destroy
    patient.update(
      first_positive_lab_at: patient.laboratories.where.not(id: id).where(result: 'positive').minimum(:specimen_collection),
      negative_lab_count: patient.laboratories.where.not(id: id).where(result: 'negative').size
    )
  end
end
