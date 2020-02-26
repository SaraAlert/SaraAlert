# frozen_string_literal: true

# Assessment: assessment model
class Assessment < ApplicationRecord
  # TODO: There's currently a hard coded symptom list, but those should be configurable
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end
  has_one :reported_condition, :class_name => 'Condition'
  has_one :symptomatic_condition, :class_name => 'Condition'
  belongs_to :patient
end
