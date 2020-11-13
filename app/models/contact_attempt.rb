# frozen_string_literal: true

# ContactAttempt: a contact attempt
class ContactAttempt < ApplicationRecord
  belongs_to :patient
  belongs_to :user
end
