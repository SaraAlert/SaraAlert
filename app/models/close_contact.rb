# frozen_string_literal: true

# CloseContact: represents a close contact of a patient
class CloseContact < ApplicationRecord
  include Utils
  include ExcelSanitizer
  include ImportExportConstants

  belongs_to :patient, touch: true

  def custom_details(fields)
    close_contact_details = {}
    (fields & CLOSE_CONTACT_FIELD_TYPES[:unfiltered]).each { |field| close_contact_details[field] = self[field] }
    (fields & CLOSE_CONTACT_FIELD_TYPES[:remove_formula_start]).each { |field| close_contact_details[field] = remove_formula_start(self[field]) }
    (fields & CLOSE_CONTACT_FIELD_TYPES[:phones]).each { |field| close_contact_details[field] = format_phone_number(self[field]) }
    close_contact_details
  end
end
