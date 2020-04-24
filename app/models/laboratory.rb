# frozen_string_literal: true

# Laboratory: represents a lab result
class Laboratory < ApplicationRecord
  belongs_to :patient
end
