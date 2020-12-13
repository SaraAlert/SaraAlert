# frozen_string_literal: true

# Helper methods for filtering through close_contacts
module CloseContactQueryHelper
  def close_contacts_by_patient_ids(patient_ids)
    CloseContact.where(patient_id: patient_ids).order(:patient_id)
  end
end
