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

  def negate
    self.int_value = 0
  end

  def as_json(options = {})
    super(options).merge({
                           value: int_value
                         })
  end
end
