# frozen_string_literal: true

# Helper methods for filtering through histories
module HistoryQueryHelper
  def histories_by_patient_ids(patient_ids)
    History.where(patient_id: patient_ids).order(:patient_id)
  end
end
