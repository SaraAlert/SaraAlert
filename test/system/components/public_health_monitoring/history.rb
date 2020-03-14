# frozen_string_literal: true

require 'application_system_test_case'

class PublicHealthMonitoringHistory < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
  
  USERS = @@system_test_utils.get_users
  
  def add_comment(comment)
    fill_in 'comment', with: comment
    click_on 'Add Comment'
  end

  def verify_comment(user_name, comment)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'p', text: comment, class: 'card-text'
    assert_selector 'span', text: 'Comment', class: 'badge'
  end
  
  def verify_monitoring_status_update(user_name, monitoring_status, status_change_reason, reasoning)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'p', text: monitoring_status, class: 'card-text'
    assert_selector 'p', text: status_change_reason, class: 'card-text'
    assert_selector 'p', text: reasoning, class: 'card-text'
    assert_selector 'span', text: 'Monitoring Change', class: 'badge'
  end

  def verify_exposure_risk_assessment_update(user_name, exposure_risk_assessment, reasoning)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'p', text: exposure_risk_assessment, class: 'card-text'
    assert_selector 'p', text: reasoning, class: 'card-text'
    assert_selector 'span', text: 'Monitoring Change', class: 'badge'
  end

  def verify_monitoring_plan_update(user_name, monitoring_plan, reasoning)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'p', text: monitoring_plan, class: 'card-text'
    assert_selector 'p', text: reasoning, class: 'card-text'
    assert_selector 'span', text: 'Monitoring Change', class: 'badge'
  end

  def verify_jurisdiction_update(user_name, jurisdiction, reasoning)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'p', text: jurisdiction, class: 'card-text'
    assert_selector 'p', text: reasoning, class: 'card-text'
    assert_selector 'span', text: 'Monitoring Change', class: 'badge'
  end

  def verify_add_report(user_name)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'span', text: 'Report Created'
  end

  def verify_edit_report(user_name)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'span', text: 'Report Updated'
  end

  def verify_all_marked_as_reviewed(user_name)
    assert_selector 'b', text: USERS[user_name]['email']
    assert_selector 'span', text: 'Reports Cleared'
  end
end
