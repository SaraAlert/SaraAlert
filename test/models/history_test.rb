# frozen_string_literal: true

require 'test_helper'

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
      assert create(:history, history_type: type, comment: 'v' * 2000, created_by: 'v' * 200)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:history, history_type: 'Invalid')
      history_types.each do |type|
        # Text column type
        create(:history, history_type: type, comment: 'v' * 2001)
        # String colomn type
        create(:history, history_type: type, created_by: 'v' * 201)
      end
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

  test 'not monitoring' do
    assert_difference('History.not_monitoring.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'I am not monitoring this patient anymore')
    end

    assert_no_difference('History.not_monitoring.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'This patient will be monitored for an additional week')
    end
  end

  test 'referral for medical evaluation' do
    assert_difference('History.referral_for_medical_evaluation.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Recommended medical evaluation of symptoms')
    end

    assert_no_difference('History.referral_for_medical_evaluation.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'I do not recommend a medical evaluation of symptoms')
    end
  end
end
