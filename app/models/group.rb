class Group < ApplicationRecord
  has_many :people
  has_many :reports
end
