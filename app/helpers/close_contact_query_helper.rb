# frozen_string_literal: true

# Helper methods for filtering through close_contacts
module CloseContactQueryHelper
  def close_contacts_by_query(patients_identifiers)
    CloseContact.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end
end
