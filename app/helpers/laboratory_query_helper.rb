# frozen_string_literal: true

# Helper methods for filtering through laboratories
module LaboratoryQueryHelper
  def laboratories_by_query(patients_identifiers)
    Laboratory.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end
end
