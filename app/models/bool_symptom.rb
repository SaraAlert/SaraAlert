# frozen_string_literal: true

# BoolSymptom: a symptom that contains a bool
class BoolSymptom < Symptom
  def value
    bool_value
  end

  def value=(value)
    self.bool_value = value
  end

  def as_json(options = {})
    super(options).merge({
                           value: bool_value
                         })
  end
end
