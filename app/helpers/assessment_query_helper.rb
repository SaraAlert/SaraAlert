# frozen_string_literal: true

# Helper methods for filtering through assessments
module AssessmentQueryHelper
  def assessments_by_query(patients_identifiers)
    Assessment.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end
end
