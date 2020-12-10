# frozen_string_literal: true

# Helper methods for filtering through histories
module HistoryQueryHelper
  def histories_by_query(patients_identifiers)
    History.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end
end
