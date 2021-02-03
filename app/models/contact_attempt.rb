# frozen_string_literal: true

# ContactAttempt: a contact attempt
class ContactAttempt < ApplicationRecord
  belongs_to :patient, touch: true
  belongs_to :user
end
