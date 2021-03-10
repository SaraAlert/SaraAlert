# frozen_string_literal: true

# CloseContact: represents a close contact of a patient
class CloseContact < ApplicationRecord
  include Utils
  include ExcelSanitizer
  include FhirHelper

  validates :primary_telephone, on: :api, phone_number: true
  validates :email, on: :api, email: true
  validates :assigned_user, on: :api, numericality: { only_integer: true,
                                                      allow_nil: true,
                                                      greater_than: 0,
                                                      less_than_or_equal_to: 999_999,
                                                      message: 'is not valid, acceptable values are numbers between 1-999999' }
  validates :contact_attempts, on: :api, numericality: { only_integer: true,
                                                         allow_nil: true,
                                                         greater_than_or_equal_to: 0,
                                                         message: 'is not valid, acceptable values are integers greater than or equal to 0' }
  validates :last_date_of_exposure, on: :api, date: true
  validates_with CompleteCloseContactValidator, on: :api

  belongs_to :patient, touch: true

  def custom_details(fields, patient_identifiers)
    close_contact_details = {}
    close_contact_details[:id] = id || '' if fields.include?(:id)
    close_contact_details[:patient_id] = patient_id || '' if fields.include?(:patient_id)
    close_contact_details[:user_defined_id_statelocal] = patient_identifiers[:user_defined_id_statelocal]
    close_contact_details[:user_defined_id_cdc] = patient_identifiers[:user_defined_id_cdc]
    close_contact_details[:user_defined_id_nndss] = patient_identifiers[:user_defined_id_nndss]
    close_contact_details[:first_name] = remove_formula_start(first_name) || '' if fields.include?(:first_name)
    close_contact_details[:last_name] = remove_formula_start(last_name) || '' if fields.include?(:last_name)
    close_contact_details[:primary_telephone] = format_phone_number(primary_telephone) || '' if fields.include?(:primary_telephone)
    close_contact_details[:email] = remove_formula_start(email) || '' if fields.include?(:email)
    close_contact_details[:contact_attempts] = contact_attempts || '' if fields.include?(:contact_attempts)
    close_contact_details[:last_date_of_exposure] = last_date_of_exposure || '' if fields.include?(:last_date_of_exposure)
    close_contact_details[:assigned_user] = assigned_user || '' if fields.include?(:assigned_user)
    close_contact_details[:notes] = remove_formula_start(notes) || '' if fields.include?(:notes)
    close_contact_details[:enrolled_id] = enrolled_id || '' if fields.include?(:enrolled_id)
    close_contact_details[:created_at] = created_at || '' if fields.include?(:created_at)
    close_contact_details[:updated_at] = updated_at || '' if fields.include?(:updated_at)
    close_contact_details
  end

  # Returns a representative FHIR::RelatedPerson for an instance of a Sara Alert Close Contact.
  # https://www.hl7.org/fhir/relatedperson.html
  def as_fhir
    close_contact_as_fhir(self)
  end
end
