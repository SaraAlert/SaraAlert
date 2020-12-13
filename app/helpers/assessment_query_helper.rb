# frozen_string_literal: true

# Helper methods for filtering through assessments
module AssessmentQueryHelper
  def assessments_by_patient_ids(patient_ids)
    Assessment.where(patient_id: patient_ids).order(:patient_id)
  end
end
