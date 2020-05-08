# frozen_string_literal: true

# AssessmentReceipt: assessment receipt model
class AssessmentReceipt < ApplicationRecord
  validates :submission_token, presence: true
end
