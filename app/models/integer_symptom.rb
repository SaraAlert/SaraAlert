# frozen_string_literal: true

# IntegerSymptom: a symptom that contains an integer
class IntegerSymptom < Symptom
  validates :int_value, numericality: { only_integer: true,
                                        less_than_or_equal_to: ActiveModel::Type::Integer.new.send(:max_value),
                                        allow_nil: true }

  def value
    int_value
  end

  def value=(value)
    self.int_value = value
  end

  # Set the symptom value to the max for this data type if the threshold operator includes
  # 'less than' such that the symptom is never counted as symptomatic by Assessment#symptom_passes_threshold
  def negate
    self.int_value = if threshold_operator&.downcase&.include?('less')
                       # Chosen number which is likely high enough in a biological context
                       # to signify that the patient responded asymptomatic
                       100_000
                     else
                       0
                     end
  end

  def as_json(options = {})
    super(options).merge({
                           value: int_value
                         })
  end
end
