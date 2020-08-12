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

  # Set the symptom value to the max for this data type if the threshold operator includes
  # 'less than' such that the symptom is never counted as symptomatic by Assessment#symptom_passes_threshold
  def negate
    self.float_value = if threshold_operator&.downcase&.include?('less')
                         # Chosen number which is likely high enough in a biological context
                         # to signify that the patient responded asymptomatic
                         99_999.99
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
