# frozen_string_literal: true

# Helper methods for filtering through transfers
module TransferQueryHelper
  def transfers_by_query(patients_identifiers)
    Transfer.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end
end
