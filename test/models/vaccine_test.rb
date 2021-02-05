# frozen_string_literal: true

require 'test_case'

class VaccineTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create vaccine' do
    assert create(:vaccine)
  end

  test 'validates group_name' do
    vaccine = create(:vaccine)

    # Group name is required and must be from a select list of values
    assert_not vaccine.update(group_name: nil)
    assert_equal(vaccine.errors.messages[:group_name].length, 2)
    assert_equal(vaccine.errors.messages[:group_name][0],
                 "value of '' is not an acceptable value, acceptable values are: '#{Vaccine::VACCINE_STANDARDS.keys.join("', '")}'")
    assert_equal(vaccine.errors.messages[:group_name][1], 'is required')

    assert_not vaccine.update(group_name: '')
    assert_equal(vaccine.errors.messages[:group_name].length, 2)
    assert_equal(vaccine.errors.messages[:group_name][0],
                 "value of '' is not an acceptable value, acceptable values are: '#{Vaccine::VACCINE_STANDARDS.keys.join("', '")}'")
    assert_equal(vaccine.errors.messages[:group_name][1], 'is required')

    assert_not vaccine.update(group_name: 'test')
    assert_equal(vaccine.errors.messages[:group_name].length, 1)
    assert_equal(vaccine.errors.messages[:group_name][0],
                 "value of 'test' is not an acceptable value, acceptable values are: '#{Vaccine::VACCINE_STANDARDS.keys.join("', '")}'")

    # If a group name updates, the product name must also be valid based on that new group name (tested separately as well)
    new_group_name = Vaccine::VACCINE_STANDARDS.keys.sample
    assert vaccine.update(group_name: new_group_name, product_name: Vaccine.product_name_options(new_group_name).sample)
  end

  test 'validates product_name' do
    vaccine = create(:vaccine)

    # Product name is required and must be from a select list of values based on the group name or 'Unknown
    assert_not vaccine.update(product_name: nil)
    assert_equal(vaccine.errors.messages[:product_name].length, 2)
    assert_equal(vaccine.errors.messages[:product_name][0], "value of '' is not an acceptable value, acceptable " \
      "values for vaccine group #{vaccine[:group_name]} are: '#{Vaccine.product_name_options(vaccine[:group_name]).join("', '")}'")
    assert_equal(vaccine.errors.messages[:product_name][1], 'is required')

    assert_not vaccine.update(product_name: '')
    assert_equal(vaccine.errors.messages[:product_name].length, 2)
    assert_equal(vaccine.errors.messages[:product_name][0], "value of '' is not an acceptable value, acceptable " \
      "values for vaccine group #{vaccine[:group_name]} are: '#{Vaccine.product_name_options(vaccine[:group_name]).join("', '")}'")
    assert_equal(vaccine.errors.messages[:product_name][1], 'is required')

    assert_not vaccine.update(product_name: 'test')
    assert_equal(vaccine.errors.messages[:product_name].length, 1)
    assert_equal(vaccine.errors.messages[:product_name][0], "value of 'test' is not an acceptable value, acceptable " \
      "values for vaccine group #{vaccine[:group_name]} are: '#{Vaccine.product_name_options(vaccine[:group_name]).join("', '")}'")

    # Should work when setting from list based on group name
    assert vaccine.update(product_name: Vaccine.product_name_options(vaccine[:group_name]).sample)

    # Unknown is an acceptable value
    assert vaccine.update(product_name: 'Unknown')
  end

  test 'validates administration_date' do
    vaccine = create(:vaccine)

    # Administration date must be a valid date
    assert_not vaccine.update(administration_date: '1-23-2020')
    assert_equal(vaccine.errors.messages[:administration_date].length, 1)
    assert_equal(vaccine.errors.messages[:administration_date][0], "is not a valid date, please use the 'YYYY-MM-DD' format")

    assert_not vaccine.update(administration_date: 'test')
    assert_equal(vaccine.errors.messages[:administration_date].length, 1)
    assert_equal(vaccine.errors.messages[:administration_date][0], "is not a valid date, please use the 'YYYY-MM-DD' format")

    # Allowed to be nil
    assert vaccine.update(administration_date: nil)
    assert vaccine.update(administration_date: DateTime.now)
  end

  test 'validates dose_number' do
    vaccine = create(:vaccine)

    # Dose number must be from a set list of options based on the max dose number
    assert_not vaccine.update(dose_number: '-1')
    assert_equal(vaccine.errors.messages[:dose_number].length, 1)
    assert_equal(vaccine.errors.messages[:dose_number][0],
                 "value of '-1' is not an acceptable value, acceptable values are: '#{Vaccine::DOSE_OPTIONS.join("', '")}'")

    assert_not vaccine.update(dose_number: '0')
    assert_equal(vaccine.errors.messages[:dose_number].length, 1)
    assert_equal(vaccine.errors.messages[:dose_number][0],
                 "value of '0' is not an acceptable value, acceptable values are: '#{Vaccine::DOSE_OPTIONS.join("', '")}'")

    assert_not vaccine.update(dose_number: (Vaccine::MAX_DOSE_NUMBER + 1).to_s)
    assert_equal(vaccine.errors.messages[:dose_number].length, 1)
    assert_equal(vaccine.errors.messages[:dose_number][0],
                 "value of '#{Vaccine::MAX_DOSE_NUMBER + 1}' is not an acceptable value, acceptable values are: '#{Vaccine::DOSE_OPTIONS.join("', '")}'")

    assert vaccine.update(dose_number: nil)
    assert vaccine.update(dose_number: '')
    assert vaccine.update!(dose_number: '2')
    assert vaccine.update(dose_number: 1) # This actually works because of Rails typecasting to match the schema
    assert vaccine.update(dose_number: 'Unknown')
    assert vaccine.update(dose_number: Vaccine::MAX_DOSE_NUMBER.to_s)
  end

  test 'validates notes length' do
    vaccine = create(:vaccine)

    # Notes length cannot be greater than 2000 characters
    assert_not vaccine.update(notes: 'a' * 2001)
    assert_equal(vaccine.errors.messages[:notes].length, 1)
    assert_equal(vaccine.errors.messages[:notes][0], 'is too long (maximum is 2000 characters)')

    assert_not vaccine.update(notes: 'a' * 3000)
    assert_equal(vaccine.errors.messages[:notes].length, 1)
    assert_equal(vaccine.errors.messages[:notes][0], 'is too long (maximum is 2000 characters)')

    assert vaccine.update(notes: 'a' * 2000)
    assert vaccine.update(notes: 'a' * 10)
    assert vaccine.update(notes: '')
    assert vaccine.update(notes: nil)
  end
end
