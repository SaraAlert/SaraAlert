# frozen_string_literal: true

# CloseContact: represents a close contact of a patient
class CloseContact < ApplicationRecord
  include Utils

  belongs_to :patient

  def custom_details(fields, patient_identifiers)
    close_contact_details = {}
    close_contact_details[:id] = id || '' if fields.include?(:id)
    close_contact_details[:patient_id] = patient_id || '' if fields.include?(:patient_id)
    close_contact_details[:user_defined_id_statelocal] = patient_identifiers[:user_defined_id_statelocal]
    close_contact_details[:user_defined_id_cdc] = patient_identifiers[:user_defined_id_cdc]
    close_contact_details[:user_defined_id_nndss] = patient_identifiers[:user_defined_id_nndss]
    close_contact_details[:first_name] = first_name || '' if fields.include?(:first_name)
    close_contact_details[:last_name] = last_name || '' if fields.include?(:last_name)
    close_contact_details[:primary_telephone] = format_phone_number(primary_telephone) || '' if fields.include?(:primary_telephone)
    close_contact_details[:email] = email || '' if fields.include?(:email)
    close_contact_details[:contact_attempts] = contact_attempts || '' if fields.include?(:contact_attempts)
    close_contact_details[:notes] = notes || '' if fields.include?(:notes)
    close_contact_details[:enrolled_id] = enrolled_id || '' if fields.include?(:enrolled_id)
    close_contact_details[:created_at] = created_at || '' if fields.include?(:created_at)
    close_contact_details[:updated_at] = updated_at || '' if fields.include?(:updated_at)
    close_contact_details
  end
end
