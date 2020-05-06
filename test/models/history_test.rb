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
      assert create(:history, history_type: type, comment: 'v' * 2000, created_by: 'v' * 200)
    end

    assert_raises(ActiveRecord::RecordInvalid) do
      create(:history, history_type: 'Invalid')
    end

    history_types.each do |type|
      assert_raises(ActiveRecord::RecordInvalid) do
        # Text column type
        create(:history, history_type: type, comment: 'v' * 2001)
      end

      assert_raises(ActiveRecord::RecordInvalid) do
        # String colomn type
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

  test 'not monitoring' do
    assert_difference('History.not_monitoring.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Not Monitoring')
    end

    assert_no_difference('History.not_monitoring.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Monitoring')
    end
  end

  test 'referral for medical evaluation' do
    assert_difference('History.referral_for_medical_evaluation.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Recommended medical evaluation of symptoms')
    end

    assert_no_difference('History.referral_for_medical_evaluation.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Recommended evaluation of symptoms')
    end
  end

  test 'document completed medical evaluation' do
    assert_difference('History.document_completed_medical_evaluation.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Document results of medical evaluation')
    end

    assert_no_difference('History.document_completed_medical_evaluation.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Document results of evaluation')
    end
  end

  test 'document medical evaluation summary and plan' do
    assert_difference('History.document_medical_evaluation_summary_and_plan.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory specimen collected')
    end

    assert_no_difference('History.document_medical_evaluation_summary_and_plan.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory collected')
    end
  end

  test 'referral for public health test' do
    assert_difference('History.referral_for_public_health_test.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Recommended laboratory testing')
    end

    assert_no_difference('History.referral_for_public_health_test.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Recommended laboratory')
    end
  end

  test 'public health test specimen received by lab results pending' do
    assert_difference('History.public_health_test_specimen_received_by_lab_results_pending.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory received specimen – result pending')
    end

    assert_no_difference('History.public_health_test_specimen_received_by_lab_results_pending.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory received specimen')
    end
  end

  test 'results of public health test positive' do
    assert_difference('History.results_of_public_health_test_positive.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory report results – positive')
    end

    assert_no_difference('History.results_of_public_health_test_positive.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory report results – negative')
    end
  end

  test 'results of public health test negative' do
    assert_difference('History.results_of_public_health_test_negative.size', 1) do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory report results – negative')
    end

    assert_no_difference('History.results_of_public_health_test_negative.size') do
      create(:history, history_type: 'Monitoring Change', comment: 'Laboratory report results – positive')
    end
  end
end
