# frozen_string_literal: true

require 'test_case'

# IMPORTANT NOTE ON CHANGES TO Time.local CALLS IN THIS FILE
# Updated Time.local to Time.local.getlocal for Rails/TimeZone because Time.local defaulted to a zone.
# In this case it was the developer machine or CI/CD server zone.
class PatientHelperTest < ActionView::TestCase
  test 'State names are normalized' do
    test_subject = Patient.new(monitored_address_state: 'New  Hampshire', address_state: 'new Hampshire',
                               additional_planned_travel_destination_state: 'NEW HAMPSHIRE ')
    normalize_state_names(test_subject)
    assert_equal('New Hampshire', test_subject.monitored_address_state)
    assert_equal('New Hampshire', test_subject.address_state)
    assert_equal('New Hampshire', test_subject.additional_planned_travel_destination_state)
  end

  test 'time zone offset for state ' do
    # DST starts 2nd Sunday in March so pick a date in May to ensure DST.
    Timecop.freeze(Time.local(2008, 5, 1, 12, 0, 0).getlocal)
    assert_equal('-04:00', time_zone_offset_for_state('Massachusetts'))
    # ST
    Timecop.freeze(Time.local(2008, 2, 1, 12, 0, 0).getlocal)
    assert_equal('-05:00', time_zone_offset_for_state('Massachusetts'))
    Timecop.return
    DateTime.now
  end

  test 'time zone offset for state returns data' do
    assert_nothing_raised do
      state_names.each do |state|
        time_zone_offset_for_state(state[0])
      end
    end
  end
end
