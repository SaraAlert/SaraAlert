# frozen_string_literal: true

require 'test_case'

class PatientHelperTest < ActiveSupport::TestCase
  include PatientHelper

  test 'State names are normalized' do
    test_subject = Patient.new(monitored_address_state: 'New  Hampshire', address_state: 'new Hampshire',
                               additional_planned_travel_destination_state: 'NEW HAMPSHIRE ')
    normalize_state_names(test_subject)
    assert_equal('New Hampshire', test_subject.monitored_address_state)
    assert_equal('New Hampshire', test_subject.address_state)
    assert_equal('New Hampshire', test_subject.additional_planned_travel_destination_state)
  end
end
