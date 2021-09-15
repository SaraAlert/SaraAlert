# frozen_string_literal: true

require 'test_case'

class HistoryTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  def history_types
    ['Report Created',
     'Report Updated',
     'Comment',
     'Enrollment',
     'Follow Up Flag',
     'Monitoring Change',
     'Reports Reviewed',
     'Report Reviewed',
     'Report Reminder',
     'Report Note'].freeze
  end

  test 'create history' do
    history_types.each do |type|
      assert create(:history, history_type: type)
      assert create(:history, history_type: type, comment: 'v' * 10_000, created_by: 'v' * 200)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:history, history_type: 'Invalid')
    end

    history_types.each do |type|
      assert_raises(ActiveRecord::RecordInvalid) do
        # Text column type
        create(:history, history_type: type, comment: 'v' * 10_001)
      end

      assert_raises(ActiveRecord::RecordInvalid) do
        # String column type
        create(:history, history_type: type, created_by: 'v' * 201)
      end
    end
  end

  test 'update patient updated_at upon history create' do
    patient = create(:patient)

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    create(:history, patient: patient)
    assert_in_delta patient.updated_at, Time.now.utc, 1

    ActiveRecord::Base.record_timestamps = false
    patient.update(updated_at: 1.day.ago)
    ActiveRecord::Base.record_timestamps = true
    create(:history, patient: patient, history_type: History::HISTORY_TYPES[:monitoree_data_downloaded])
    assert_in_delta patient.updated_at, 1.day.ago, 1
  end

  test 'history in time frame' do
    assert_no_difference("History.in_time_frame('Invalid').size") do
      create(:history, history_type: 'Comment')
    end

    create(:history, history_type: 'Comment')
    assert_equal 0, History.in_time_frame('Invalid').size

    assert_difference("History.in_time_frame('Yesterday').size", 1) do
      create(:history, history_type: 'Comment')
    end

    assert_no_difference("History.in_time_frame('Yesterday').size", 1) do
      create(:history, history_type: 'Comment').update(created_at: 25.hours.ago)
    end

    assert_no_difference("History.in_time_frame('Last 14 Days').size") do
      create(:history, history_type: 'Comment').update(created_at: 15.days.ago)
    end

    # Specific case where we don't want the number to change throughout the day
    assert_no_difference("History.in_time_frame('Last 14 Days').size") do
      create(:history, history_type: 'Comment')
    end

    assert_difference("History.in_time_frame('Last 14 Days').size", 1) do
      create(:history, history_type: 'Comment').update(created_at: DateTime.now.utc - 1.day)
    end

    assert_difference("History.in_time_frame('Total').size", 1) do
      create(:history, history_type: 'Comment').update(created_at: 15.days.ago)
    end
  end

  test 'history types that should not touch the patient record' do
    patient = create(:patient)
    patient.update(updated_at: 100.days.ago)
    assert patient.updated_at < 98.days.ago

    History.report_reminder(patient: patient)
    assert patient.updated_at < 98.days.ago

    History.unsuccessful_report_reminder(patient: patient)
    assert patient.updated_at < 98.days.ago

    History.monitoree_data_downloaded(patient: patient)
    assert patient.updated_at < 98.days.ago

    History.report_email_error(patient: patient)
    assert patient.updated_at < 98.days.ago
  end
end
