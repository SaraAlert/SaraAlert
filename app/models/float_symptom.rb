# frozen_string_literal: true

# FloatSymptom: a symptom that contains a float
class FloatSymptom < Symptom
  def value
    float_value
  end

  def value=(value)
    self.float_value = value
  end

  def as_json(options = {})
    super(options).merge({
                           value: float_value
                         })
  end
end
