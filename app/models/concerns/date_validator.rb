# frozen_string_literal: true

# Validates that a given date (attribute) is valid
class DateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    err_msg = 'is not a valid date'
    # If we can, validate using the pre-type cast value, since this will more accurately reflect user input
    value = record.public_send("#{attribute}_before_type_cast") || value
    # Blank, Date, DateTime, and Time values are accepted.
    return if value.blank? || value.is_a?(Date) || value.is_a?(DateTime) || value.is_a?(Time)

    # Numeric dates do not conform to import or API guidance
    # Strings should respond to match and conform to import and API guidance
    if value.is_a?(Numeric) || !value.respond_to?(:match?)
      record.errors.add(attribute, "#{err_msg}, please use the 'YYYY-MM-DD' format")
      return
    end

    unless value.match?(/^\d{4}-\d{2}-\d{2}$/)
      if value.match?(%r{^\d{2}/\d{2}/\d{4}$})
        record.errors.add(attribute, "#{err_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead")
      else
        record.errors.add(attribute, "#{err_msg}, please use the 'YYYY-MM-DD' format")
      end
      return
    end

    begin
      Date.parse(value)
    rescue ArgumentError
      record.errors.add(attribute, 'is not a valid date')
    end
  end
end
