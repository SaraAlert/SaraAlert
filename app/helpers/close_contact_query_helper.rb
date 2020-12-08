# frozen_string_literal: true

# Helper methods for filtering through close_contacts
module CloseContactQueryHelper
  def close_contacts_by_query(patients_identifiers)
    CloseContact.where(patient_id: patients_identifiers.keys).order(:patient_id)
  end

  def extract_close_contacts_details(patients_identifiers, close_contacts, fields)
    close_contacts_details = []
    close_contacts.each do |close_contact|
      close_contact_details = {}
      close_contact_details[:patient_id] = close_contact[:patient_id] || '' if fields.include?(:patient_id)
      %i[user_defined_id_statelocal user_defined_id_cdc user_defined_id_nndss].each do |identifier|
        close_contact_details[identifier] = patients_identifiers[close_contact[:patient_id]][identifier] || '' if fields.include?(identifier)
      end
      close_contact_details[:id] = close_contact[:id] || '' if fields.include?(:id)
      close_contact_details[:first_name] = close_contact[:first_name] || '' if fields.include?(:first_name)
      close_contact_details[:last_name] = close_contact[:last_name] || '' if fields.include?(:last_name)
      close_contact_details[:primary_telephone] = format_phone_number(close_contact[:primary_telephone]) || '' if fields.include?(:primary_telephone)
      close_contact_details[:email] = close_contact[:email] || '' if fields.include?(:email)
      close_contact_details[:contact_attempts] = close_contact[:contact_attempts] || '' if fields.include?(:contact_attempts)
      close_contact_details[:notes] = close_contact[:notes] || '' if fields.include?(:notes)
      close_contact_details[:enrolled_id] = close_contact[:enrolled_id] || '' if fields.include?(:enrolled_id)
      close_contact_details[:created_at] = close_contact[:created_at]&.strftime('%F') || '' if fields.include?(:created_at)
      close_contact_details[:updated_at] = close_contact[:updated_at]&.strftime('%F') || '' if fields.include?(:updated_at)
      close_contacts_details << close_contact_details
    end
    close_contacts_details
  end
end
