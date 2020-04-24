# frozen_string_literal: true

# Symptom
class Symptom < ApplicationRecord
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  def self.valid_types
    %w[FloatSymptom BoolSymptom IntegerSymptom]
  end

  validates :type, inclusion: valid_types, presence: true

  scope :fever, lambda {
    where(['name = ? and bool_value = ?', 'fever', true])
  }

  scope :fever_medication, lambda {
    where(['name = ? and bool_value = ?', 'used-a-fever-reducer', true])
  }

  def as_json(options = {})
    super(options).merge({
                           type: type
                         })
  end
end
