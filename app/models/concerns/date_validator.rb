# frozen_string_literal: true

# Validates that a given phone number (attribute) is valid
class DateValidator < ActiveModel::EachValidator
  include ValidationHelper
  def validate_each(record, attribute, value)
    value = record.public_send("#{attribute}_before_type_cast") if options[:before_type_cast]
    
    return if value.blank? || value.instance_of?(Date)

    unless value.match(/\d{4}-\d{2}-\d{2}/)
      err_msg = "'#{value}' is not a valid date for '#{VALIDATION[attribute][:label]}'"
      if value.match(%r{\d{2}/\d{2}/\d{4}})
        record.errors.add(attribute, "#{err_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead")
      else
        record.errors.add(attribute, "#{err_msg} due to ambiguity between 'MM/DD/YYYY' and 'DD/MM/YYYY', please use the 'YYYY-MM-DD' format instead")
      end
      return
    end

    begin
      Date.parse(value)
    rescue ArgumentError
      record.errors.add(attribute, "'#{value}' is not a valid date for '#{VALIDATION[attribute][:label]}'")
    end
  end
end