# frozen_string_literal: true

# Laboratory: represents a lab result
class Laboratory < ApplicationRecord
  include ValidationHelper
  include FhirHelper

  belongs_to :patient, touch: true

  RESULT_TO_CODE = {
    positive: { system: 'http://snomed.info/sct', code: '10828004' },
    negative: { system: 'http://snomed.info/sct', code: '260385009' },
    indeterminate: { system: 'http://snomed.info/sct', code: '82334004' },
    other: { system: 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor', code: 'OTH' }
  }.freeze
  CODE_TO_RESULT = {
    **RESULT_TO_CODE
  }.invert.freeze
  LAB_TYPE_TO_CODE = {
    PCR: { system: 'http://loinc.org', code: '94500-6' },
    Antigen: { system: 'http://loinc.org', code: '94558-4' },
    'Total Antibody': { system: 'http://loinc.org', code: '94762-2' },
    'IgG Antibody': { system: 'http://loinc.org', code: '94563-4' },
    'IgM Antibody': { system: 'http://loinc.org', code: '94564-2' },
    'IgA Antibody': { system: 'http://loinc.org', code: '94562-6' },
    Other: { system: 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor', code: 'OTH' },
    '': { system: 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor', code: 'UNK' }
  }.freeze
  CODE_TO_LAB_TYPE = {
    **LAB_TYPE_TO_CODE
  }.invert.freeze

  validates :result, inclusion: {
    in: [*RESULT_TO_CODE.keys.map(&:to_s), nil, ''],
    message: "is not an acceptable value, acceptable values are: '#{RESULT_TO_CODE.keys.map(&:to_s).reject(&:blank?).join("', '")}'"
  }

  validates :lab_type, on: %i[api import], inclusion: {
    in: VALID_PATIENT_ENUMS[:lab_type],
    message: "is not an acceptable value, acceptable values are: '#{VALID_PATIENT_ENUMS[:lab_type].reject(&:blank?).join("', '")}'"
  }

  %i[specimen_collection
     report].each do |date_field|
    validates date_field, on: %i[api import], date: true
  end

  validates_with LaboratoryDateValidator, on: %i[api import]

  before_destroy :update_patient_linelist_before_destroy
  after_save :update_patient_linelist_after_save

  # Returns a representative FHIR::Observation for an instance of a Sara Alert Laboratory.
  # https://www.hl7.org/fhir/observation.html
  def as_fhir
    laboratory_as_fhir(self)
  end

  def self.code_to_result(system, code)
    CODE_TO_RESULT[{ system: system, code: code&.upcase }]
  end

  def self.result_to_code(result)
    RESULT_TO_CODE[result&.to_sym]
  end

  def self.code_to_lab_type(system, code)
    CODE_TO_LAB_TYPE[{ system: system, code: code&.upcase }]
  end

  def self.lab_type_to_code(lab_type)
    # The lab type must always be specified in FHIR, so when no code can be found, we default to 'UNK'
    LAB_TYPE_TO_CODE[lab_type&.to_sym] || { system: 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor', code: 'UNK' }
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
