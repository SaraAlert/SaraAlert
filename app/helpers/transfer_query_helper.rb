# frozen_string_literal: true

# Helper methods for filtering through transfers
module TransferQueryHelper
  def transfers_by_patient_ids(patient_ids)
    Transfer.where(patient_id: patient_ids).order(:patient_id)
  end
end
