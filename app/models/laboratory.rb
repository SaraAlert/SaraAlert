# frozen_string_literal: true

# Laboratory: represents a lab result
class Laboratory < ApplicationRecord
  belongs_to :patient

  validates :result, inclusion: { in: ['positive', 'negative', 'indeterminate', 'other', nil, ''] }

  scope :last_ten_days_positive, lambda {
    where('specimen_collection > ?', 10.days.ago).where(result: 'positive')
  }

  scope :before_ten_days_positive, lambda {
    where('specimen_collection <= ?', 10.days.ago).where(result: 'positive')
  }

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
end
