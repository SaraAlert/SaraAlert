# frozen_string_literal: true

# Validates that the international phone number is valid
class InternationalPhoneNumberValidator < ActiveModel::Validator
  def validate(record)
    value = record.international_telephone
    return if value.blank?

    if value.length > 50
      record.errors.add(:base, "Value '#{value}' is not a valid international phone number, international phone number can only be up to 50 characters")
    end

    return if value == value&.gsub(/[^0-9.\-()+ ]/, '')

    record.errors.add(:base, "Value '#{value}' is not a valid international phone number, please only use valid characters which include digits, \
                             \".\", \"-\", \"(\", \")\", \"+\", \" \".\"")
  end
end
