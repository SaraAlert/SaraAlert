# frozen_string_literal: true

# CloseContact: represents a close contact of a patient
class CloseContact < ApplicationRecord
  include Utils
  include ExcelSanitizer

  belongs_to :patient, touch: true
end
