# frozen_string_literal: true

# FloatSymptom: a symptom that contains a float
# ActiveRecord will automatically typecast Integers and 'false' to Float.
# Methods that create FloatSymptoms should keep the above in mind.
class FloatSymptom < Symptom
  validates :float_value, numericality: { allow_nil: true }

  def value
    float_value
  end

  def value=(value)
    self.float_value = value
  end

  def negate
    self.float_value = if threshold_operator&.downcase&.include?('less')
                         3.402823466e38
                       else
                         0.0
                       end
  end

  def as_json(options = {})
    super(options).merge({
                           value: float_value
                         })
  end
end
