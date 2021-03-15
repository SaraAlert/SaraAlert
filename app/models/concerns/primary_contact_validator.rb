# frozen_string_literal: true

# Validates that a primary contact
class PrimaryContactValidator < ActiveModel::Validator
  include ValidationHelper
  def validate(record)
    if record.email.blank? && record.preferred_contact_method == 'E-mailed Web Link'
      record.errors.add(:base, "#{VALIDATION[:email][:label]} is required when 'Primary Contact Method' is 'E-mailed Web Link'")
    end
    return unless record.primary_telephone.blank? && ['SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].include?(record.preferred_contact_method)

    record.errors.add(:base, "#{VALIDATION[:primary_telephone][:label]} is required when 'Primary Contact Method' is '#{record.preferred_contact_method}'")
  end
end
