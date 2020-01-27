class Patient < ApplicationRecord
  belongs_to :responder, class_name: 'Patient'
  has_many :dependents, class_name: 'Patient', foreign_key: 'responder_id'
  has_many :assessments
end
