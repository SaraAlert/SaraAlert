# frozen_string_literal: true

# SaraAlert dates of birth should not be before January 1, 1900
class DateOfBirthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, 'cannot occur before January 1, 1900') unless valid?(value)
  end

  private

  def  valid?(value)
    if value.nil?
      true
    elsif !value.acts_like?(:date)
      false
    else
      !(value < Date.new(1900,1,1))
    end
  end
end
