# frozen_string_literal: true

# Helper methods for filtering through laboratories
module LaboratoryQueryHelper
  def laboratories_by_patient_ids(patient_ids)
    Laboratory.where(patient_id: patient_ids).order(:patient_id)
  end
end
