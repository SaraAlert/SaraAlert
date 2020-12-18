# frozen_string_literal: true

# Contains generic helper methods
module Utils
  # Converts phone number from e164 to CDC recommended format
  def format_phone_number(phone)
    cleaned_phone_number = Phonelib.parse(phone).national(false)
    return nil if cleaned_phone_number.nil? || cleaned_phone_number.length != 10

    cleaned_phone_number.insert(6, '-').insert(3, '-')
  end

  # Removes spaces, dashes, and periods and converts string to lowercase to try to match field value if only off by small punctuation differences
  def normalize_enum_field_value(value)
    value.to_s.downcase.gsub(/[ -.]/, '')
  end
end
