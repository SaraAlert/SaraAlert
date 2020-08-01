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

  test 'history in time frame' do
    assert_no_difference("History.in_time_frame('Invalid').size") do
      create(:history, history_type: 'Comment')
    end

    create(:history, history_type: 'Comment')
    assert_equal 0, History.in_time_frame('Invalid').size

    assert_difference("History.in_time_frame('Last 24 Hours').size", 1) do
      create(:history, history_type: 'Comment')
    end

    assert_no_difference("History.in_time_frame('Last 24 Hours').size", 1) do
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
      create(:history, history_type: 'Comment').update(created_at: 1.day.ago)
    end

    assert_difference("History.in_time_frame('Total').size", 1) do
      create(:history, history_type: 'Comment').update(created_at: 15.days.ago)
    end
  end
end
