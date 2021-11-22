# frozen_string_literal: true

# Helper methods for filtering through common_exposure_cohorts
module CommonExposureCohortQueryHelper
  def common_exposure_cohorts_by_patient_ids(patient_ids)
    CommonExposureCohort.where(patient_id: patient_ids).order(:patient_id)
  end
end
