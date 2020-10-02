# frozen_string_literal: true

# Several Patient attributes should not be more than 30 days into the future.
class AtMostThirtyDaysFromNowValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'cannot be more than 30 days from now') unless valid?(value)
  end

  private

  def  valid?(value)
    if value.nil?
      true
    elsif !value.acts_like?(:date)
      false
    else
      value <= (Date.today + 30.days)
    end
  end
end
