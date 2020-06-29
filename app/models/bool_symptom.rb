# frozen_string_literal: true

# BoolSymptom: a symptom that contains a bool
# ActiveRecord will automatically typecast most types to Boolean.
# Methods that create BoolSymptoms should keep the above in mind.
class BoolSymptom < Symptom
  validates :bool_value, inclusion: { in: [true, false, nil] }

  def value
    bool_value
  end

  def value=(value)
    self.bool_value = value
  end

  def negate
    self.bool_value = !value
  end

  def as_json(options = {})
    super(options).merge({
                           value: bool_value
                         })
  end
end
