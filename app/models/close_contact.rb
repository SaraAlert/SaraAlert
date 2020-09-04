# frozen_string_literal: true

# CloseContact: represents a close contact of a patient
class CloseContact < ApplicationRecord
  belongs_to :patient

  default_scope { order(created_at: :desc) }
end
