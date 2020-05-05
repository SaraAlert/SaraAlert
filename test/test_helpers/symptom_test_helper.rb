# frozen_string_literal: true

module SymptomTestHelper
  def self.create_symptom_as_hash(kname: 'Name', value: 1, type: 'IntegerSymptom', label: 'Label', notes: 'Notes')
    {
      "name": kname,
      "value": value,
      "type": type,
      "label": label,
      "notes": notes
    }
  end

  def self.get_value(symptom)
    return nil unless symptom.is_a?(::Symptom)

    case symptom.type
    when 'IntegerSymptom'
      symptom.int_value
    when 'BoolSymptom'
      symptom.bool_value
    when 'FloatSymptom'
      symptom.float_value
    end
  end
end
