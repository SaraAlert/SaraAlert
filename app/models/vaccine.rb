# frozen_string_literal: true

# Represents a vaccination for a Patient
class Vaccine < ApplicationRecord
  include FhirHelper
  belongs_to :patient

  VACCINE_STANDARDS = Rails.configuration.vaccine_standards.freeze

  # Finds the highest number of doses required based on the number for each vaccine in the config.
  MAX_DOSE_NUMBER = VACCINE_STANDARDS.values.collect { |group| group['vaccines'].collect { |vaccine| vaccine['num_doses'] } }.flatten.max

  # Additional allowed options for a selected product name aside from the configured official options
  ADDITIONAL_PRODUCT_NAME_OPTIONS = [
    { 'product_name' => 'Unknown', 'product_codes' => [{ 'system' => 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor', 'code' => 'UNK' }] }
  ].freeze

  # An array of strings representing the options for the vaccine dose number.
  DOSE_OPTIONS = (1..MAX_DOSE_NUMBER).to_a.map(&:to_s) + ['Unknown', '', nil].freeze

  # --- FIELD VALIDATION --- #
  validates :group_name, inclusion: {
    # This method syntax is necessary for the getter method to be in scope
    in: ->(_vaccine) { group_name_options },
    message: lambda { |_vaccine, _data|
      "is not an acceptable value, acceptable values are: '#{group_name_options.join("', '")}'"
    }
  }, presence: { message: 'is required' }

  # Product name valid options depend on the current group name
  validates :product_name, inclusion: {
    in: ->(vaccine) { product_name_options(vaccine[:group_name]) },
    message: lambda { |vaccine, _data|
      'is not an acceptable value, acceptable values for vaccine ' \
        "group #{vaccine[:group_name]} are: '#{product_name_options(vaccine[:group_name]).join("', '")}'"
    }
  }, presence: { message: 'is required' }

  validates :administration_date, date: true

  validates :dose_number, inclusion: {
    in: DOSE_OPTIONS,
    message: lambda { |_vaccine, _data|
      "is not an acceptable value, acceptable values are: '#{DOSE_OPTIONS.join("', '")}'"
    }
  }
  validates :notes, length: { maximum: 2000 }

  # Return the vaccine as a FHIR Immunization
  def as_fhir
    vaccine_as_fhir(self)
  end

  # Gets the list of possible vaccine group names from the vaccine config.
  def self.group_name_options
    VACCINE_STANDARDS.keys
  end

  # Gets the product names of the vaccines in the specified group from the vaccine config.
  # Returns an array of string values.
  # Params:
  # - vaccine_group (sym) Group to fetch product names for
  def self.product_name_options(vaccine_group)
    vaccine_group = VACCINE_STANDARDS[vaccine_group]
    return [] if vaccine_group.blank? || vaccine_group['vaccines'].blank?

    vaccine_group['vaccines'].map { |vaccine| vaccine['product_name'] } + ADDITIONAL_PRODUCT_NAME_OPTIONS.map { |option| option['product_name'] }
  end

  # Gets the codes relevant to a specified vaccine in a specified group.
  # Returns: an array of hashes of the form {code: <string>, system: <string>}
  # Params:
  # - vaccine_group: Group that the vaccine is in
  # - product_name: Name of the vaccine for which to return the codes
  def self.product_codes_by_name(vaccine_group, product_name)
    vaccine_group = VACCINE_STANDARDS[vaccine_group]
    return [] if vaccine_group.blank? || vaccine_group['vaccines'].blank?

    (vaccine_group['vaccines'] + ADDITIONAL_PRODUCT_NAME_OPTIONS).find { |vaccine| vaccine['product_name'] == product_name }&.dig('product_codes') || []
  end

  # Gets the product_name for a vaccine given a group to look in, and a system and code which refer to the vaccine
  # Returns: The name of the vaccine
  # Params:
  # - vaccine_group: The vaccine group to look in
  # - product_system: The system of the code
  # - product_code: The code within the system that refers to the desired vaccine
  def self.product_name_by_code(vaccine_group, product_system, product_code)
    vaccine_group = VACCINE_STANDARDS[vaccine_group]
    return nil if vaccine_group.blank? || vaccine_group['vaccines'].blank?

    (vaccine_group['vaccines'] + ADDITIONAL_PRODUCT_NAME_OPTIONS).find do |vaccine|
      vaccine['product_codes']&.any? { |code| code['system'] == product_system && code['code'] == product_code }
    end&.dig('product_name')
  end

  # Gets the codes relevant to a specified group of vaccines.
  # Returns: an array of hashes of the form {code: <string>, system: <string>}
  # Params:
  # - vaccine_group: The group to find the codes for
  def self.group_codes_by_name(vaccine_group)
    vaccine_group = VACCINE_STANDARDS[vaccine_group]
    return [] if vaccine_group.blank? || vaccine_group['codes'].blank?

    vaccine_group['codes']
  end

  # Gets group_name for a vaccine given a code that refers to that group
  # Returns: The name of the group
  # Params:
  # - group_system: The system of the code
  # - group_code: The code within the system that refers to the desired vaccine group
  def self.group_name_by_code(group_system, group_code)
    VACCINE_STANDARDS.values.find do |value|
      value['codes'].any? { |code| code['system'] == group_system && code['code'] == group_code }
    end&.dig('name')
  end
end
