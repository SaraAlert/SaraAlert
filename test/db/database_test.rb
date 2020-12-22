# frozen_string_literal: true

require 'test_case'

class DatabaseTest < ActiveSupport::TestCase
  include PatientHelper

  test 'DATE_SUB and DATE_ADD work was expected' do
    [
      "SELECT '2021-01-03' = DATE(DATE_SUB(CONVERT_TZ('2021-01-04 00:00:00', 'UTC', 'UTC'), INTERVAL 1440 MINUTE))",
      "SELECT '2021-01-03' = DATE(DATE_SUB(CONVERT_TZ('2021-01-04 00:00:00', 'UTC', 'UTC'), INTERVAL 720 MINUTE))",
      "SELECT '2021-01-02' = DATE(DATE_SUB(CONVERT_TZ('2021-01-04 00:00:00', 'UTC', 'UTC'), INTERVAL 1441 MINUTE))",
      "SELECT '2021-01-03' = DATE(DATE_SUB(DATE('2021-01-04'), INTERVAL 1 DAY))"
    ].each do |sql|
      result = ActiveRecord::Base.connection.execute(sql).first
      assert_equal 1, result[0]
    end
  end

  test 'null and empty comparison works as expected' do
    patient_1 = create(:patient, monitored_address_state: nil)
    patient_2 = create(:patient, monitored_address_state: '')
    patient_3 = create(:patient, monitored_address_state: 'California')
    assert_not_nil Patient.where('monitored_address_state IS NULL OR monitored_address_state = ""').find_by(id: patient_1.id)
    assert_not_nil Patient.where('monitored_address_state IS NULL OR monitored_address_state = ""').find_by(id: patient_2.id)
    assert_nil Patient.where('monitored_address_state IS NULL OR monitored_address_state = ""').find_by(id: patient_3.id)

    # At least in MySQL: '' = '   ' is true
    assert_not_nil Patient.where('monitored_address_state IS NULL OR monitored_address_state = "   "').find_by(id: patient_1.id)
    assert_not_nil Patient.where('monitored_address_state IS NULL OR monitored_address_state = "      "').find_by(id: patient_2.id)
    assert_nil Patient.where('monitored_address_state IS NULL OR monitored_address_state = "  "').find_by(id: patient_3.id)
  end

  test 'Time zone comparisons work as expected' do
    # NOTE: You CANNOT compare using two DATETIME in different timezones.
    #       DATETIME MUST be converted to the same timezone.
    [
      "SELECT '2021-01-04 19:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'UTC')",
      "SELECT '2021-01-04 14:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'America/New_York')",
      "SELECT '2021-01-04 13:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'America/Chicago')",
      "SELECT '2021-01-04 10:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'America/Juneau')",
      "SELECT '2021-01-04 8:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'Pacific/Pago_Pago')",
      "SELECT '2021-01-04 12:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'America/Phoenix')",
      "SELECT '2021-01-04 11:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'America/Los_Angeles')",
      "SELECT '2021-01-04 12:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'America/Denver')",
      "SELECT '2021-01-04 6:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'Pacific/Noumea')",
      "SELECT '2021-01-04 5:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'Pacific/Guam')",
      "SELECT '2021-01-04 9:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'Pacific/Honolulu')",
      "SELECT '2021-01-04 7:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'Pacific/Majuro')",
      "SELECT '2021-01-04 4:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'Asia/Tokyo')",
      "SELECT '2021-01-04 15:00:00' < CONVERT_TZ('2021-01-04 19:00:01', 'UTC', 'America/Puerto_Rico')"
    ].each do |sql|
      result = ActiveRecord::Base.connection.execute(sql).first
      assert_equal 1, result[0]
    end

    [
      "SELECT '2021-01-04 19:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'UTC')",
      "SELECT '2021-01-04 14:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'America/New_York')",
      "SELECT '2021-01-04 13:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'America/Chicago')",
      "SELECT '2021-01-04 10:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'America/Juneau')",
      "SELECT '2021-01-04 8:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'Pacific/Pago_Pago')",
      "SELECT '2021-01-04 12:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'America/Phoenix')",
      "SELECT '2021-01-04 11:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'America/Los_Angeles')",
      "SELECT '2021-01-04 12:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'America/Denver')",
      "SELECT '2021-01-05 6:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'Pacific/Noumea')",
      "SELECT '2021-01-05 5:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'Pacific/Guam')",
      "SELECT '2021-01-04 9:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'Pacific/Honolulu')",
      "SELECT '2021-01-05 7:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'Pacific/Majuro')",
      "SELECT '2021-01-05 4:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'Asia/Tokyo')",
      "SELECT '2021-01-04 15:00:00' < CONVERT_TZ('2021-01-04 18:59:59', 'UTC', 'America/Puerto_Rico')"
    ].each do |sql|
      result = ActiveRecord::Base.connection.execute(sql).first
      assert_equal 0, result[0]
    end
  end

  test 'SQL timezone conversion equals rails timezone conversion' do
    patient = create(:patient)
    state_names.each_key do |state|
      patient.update(monitored_address_state: state)
      patient.reload

      rails_local_time = patient.curr_date_in_timezone
      rails_utc_time = rails_local_time.getlocal('+00:00')
      query = ActiveRecord::Base.connection.raw_connection.prepare("SELECT CONVERT_TZ(?, 'UTC', ?);")
      sql_time = query.execute(rails_utc_time, patient.time_zone).first[0]
      assert_equal sql_time.strftime('%Y-%m-%d %H:%M:%S'), rails_local_time.strftime('%Y-%m-%d %H:%M:%S')
    end
  end

  test 'MySQL date compare works as expected' do
    dt = Time.now.getlocal('-00:00').beginning_of_day
    query = ActiveRecord::Base.connection.raw_connection.prepare('SELECT Date(?) = ?')
    results = query.execute(dt, dt)
    assert_equal 1, results.first.first
    query.close

    # This test isd a sanity check to verify that casting to a DATE in MySQL
    # effectively gives us the beginning of the day and is considered less than
    # one second past the beginning of the day
    dt += 1.second
    query = ActiveRecord::Base.connection.raw_connection.prepare('SELECT Date(?) < ?')
    results = query.execute(dt, dt)
    assert_equal 1, results.first.first
    query.close

    query = ActiveRecord::Base.connection.raw_connection.prepare('SELECT Date(?) > ?')
    results = query.execute(dt, dt)
    assert_equal 0, results.first.first
    query.close

    query = ActiveRecord::Base.connection.raw_connection.prepare('SELECT Date(?) != ?')
    results = query.execute(dt, dt)
    assert_equal 1, results.first.first
    query.close
  end

  test 'MySQL hour works as expected' do
    (0..23).each do |hour|
      dt = Time.now.getlocal('-00:00').change(hour: hour)
      query = ActiveRecord::Base.connection.raw_connection.prepare('SELECT HOUR(?)')
      results = query.execute(dt)
      assert_equal hour, results.first.first
      query.close
    end
  end
end
