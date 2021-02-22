# frozen_string_literal: true

# Laboratory: represents a lab result
class Laboratory < ApplicationRecord
  include ValidationHelper
  belongs_to :patient, touch: true

  %i[result
     lab_type].each do |enum_field|
    validates enum_field, on: %i[api import], inclusion: {
      in: VALID_PATIENT_ENUMS[enum_field],
      message: "is not an acceptable value, acceptable values are: '#{VALID_PATIENT_ENUMS[enum_field].reject(&:blank?).join("', '")}'"
    }
  end

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

  # Information about this laboratory
  def details
    {
      patient_id: patient_id || '',
      lab_type: lab_type || '',
      lab_specimen_collection: specimen_collection || '',
      lab_report: report || '',
      lab_result: result || '',
      lab_created_at: created_at || '',
      lab_updated_at: updated_at || ''
    }
  end

  def custom_details(fields, patient_identifiers)
    laboratory_details = {}
    laboratory_details[:id] = id || '' if fields.include?(:id)
    laboratory_details[:patient_id] = patient_id || '' if fields.include?(:patient_id)
    laboratory_details[:user_defined_id_statelocal] = patient_identifiers[:user_defined_id_statelocal]
    laboratory_details[:user_defined_id_cdc] = patient_identifiers[:user_defined_id_cdc]
    laboratory_details[:user_defined_id_nndss] = patient_identifiers[:user_defined_id_nndss]
    laboratory_details[:lab_type] = lab_type || '' if fields.include?(:lab_type)
    laboratory_details[:specimen_collection] = specimen_collection&.strftime('%F') || '' if fields.include?(:specimen_collection)
    laboratory_details[:report] = report&.strftime('%F') || '' if fields.include?(:report)
    laboratory_details[:result] = result || '' if fields.include?(:result)
    laboratory_details[:created_at] = created_at || '' if fields.include?(:created_at)
    laboratory_details[:updated_at] = updated_at || '' if fields.include?(:updated_at)
    laboratory_details
  end

  private

  def update_patient_linelist_after_save
    patient.update(
      latest_positive_lab_at: patient.laboratories.where(result: 'positive').maximum(:specimen_collection),
      negative_lab_count: patient.laboratories.where(result: 'negative').size
    )
  end

  def update_patient_linelist_before_destroy
    patient.update(
      latest_positive_lab_at: patient.laboratories.where.not(id: id).where(result: 'positive').maximum(:specimen_collection),
      negative_lab_count: patient.laboratories.where.not(id: id).where(result: 'negative').size
    )
  end
end
