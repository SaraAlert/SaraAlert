# frozen_string_literal: true

require 'test_helper'

class HistoryTest < ActiveSupport::TestCase
  def setup; end

  def teardown; end

  test 'create history' do
    assert create(:history, history_type: 'Report Created')
    assert create(:history, history_type: 'Report Updated')
    assert create(:history, history_type: 'Comment')
    assert create(:history, history_type: 'Enrollment')
    assert create(:history, history_type: 'Monitoring Change')
    assert create(:history, history_type: 'Reports Reviewed')
    assert create(:history, history_type: 'Report Reviewed')
    assert create(:history, history_type: 'Report Reminder')
    assert create(:history, history_type: 'Report Note')
    assert create(:history, history_type: 'Comment', comment: 'v' * 2000)
    assert create(:history, history_type: 'Comment', created_by: 'v' * 200)

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:history, history_type: 'Invalid')
      # Text column type
      create(:history, history_type: 'Comment', comment: 'v' * 2001)
      # String colomn type
      create(:history, history_type: 'Comment', created_by: 'v' * 201)
    end
  end

  test 'in time frame' do
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

    assert_difference("History.in_time_frame('Last 14 Days').size", 1) do
      create(:history, history_type: 'Comment')
    end
  end
end
