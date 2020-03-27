# frozen_string_literal: true

# Transfer: transfer model
class Transfer < ApplicationRecord
  belongs_to :to_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :from_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :who, class_name: 'User'
  belongs_to :patient

  def from_path
    from_jurisdiction&.jurisdiction_path_string
  end

  def to_path
    to_jurisdiction&.jurisdiction_path_string
  end
end
