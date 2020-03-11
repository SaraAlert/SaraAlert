# frozen_string_literal: true

# IntegerSymptom: a symptom that contains an integer
class IntegerSymptom < Symptom
  def value
    int_value
  end

  def value=(value)
    self.int_value = value
  end

  def as_json(options = {})
    super(options).merge({
                           value: int_value
                         })
  end
end
