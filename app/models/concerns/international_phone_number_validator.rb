# frozen_string_literal: true

# Validates that the international phone number is valid
class InternationalPhoneNumberValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    record.errors.add(attribute, 'is not a valid international phone number, international phone number can only be up to 50 characters') if value.length > 50

    return if value == value&.gsub(/[^0-9.\-()+ ]/, '')

    record.errors.add(attribute, 'is not a valid international phone number, please only use valid characters which include digits, '\
                             '".", "-", "(", ")", "+", " "')
  end
end
