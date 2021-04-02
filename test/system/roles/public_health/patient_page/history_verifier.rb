# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../../lib/system_test_utils'

class PublicHealthPatientPageHistoryVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_monitoring_status(user_label, monitoring_status, monitoring_reason, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed Monitoring Status', monitoring_status, monitoring_reason, reasoning])
  end

  def verify_exposure_risk_assessment(user_label, exposure_risk_assessment, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed Exposure Risk Assessment', exposure_risk_assessment, reasoning])
  end

  def verify_monitoring_plan(user_label, monitoring_plan, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed Monitoring Plan', monitoring_plan, reasoning])
  end

  def verify_latest_public_health_action(user_label, latest_public_health_action, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed Latest Public Health Action', latest_public_health_action, reasoning])
  end

  def verify_additional_public_health_action(user_label)
    verify_historical_event(user_label, 'Monitoring Change', ['User added an additional Public Health Action'])
  end

  def verify_current_workflow(user_label, current_workflow, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed Workflow', current_workflow, reasoning])
  end

  def verify_assigned_jurisdiction(user_label, jurisdiction, reasoning, creator = 'User')
    verify_historical_event(user_label, 'Monitoring Change', ["#{creator} changed Jurisdiction", jurisdiction, reasoning])
  end

  def verify_assigned_user(user_label, assigned_user, reasoning, creator = 'User')
    verify_historical_event(user_label, 'Monitoring Change', ["#{creator} changed Assigned User", assigned_user, reasoning])
  end

  def verify_add_report(user_label)
    verify_historical_event(user_label, 'Report Created', ['User created a new report'])
  end

  def verify_edit_report(user_label)
    verify_historical_event(user_label, 'Report Updated', ['User updated an existing report'])
  end

  def verify_add_note_to_report(user_label, assessment_id, note)
    verify_historical_event(user_label, 'Report Note', ['User left a note for a report', assessment_id, note])
  end

  def verify_mark_all_as_reviewed(user_label, reasoning)
    verify_historical_event(user_label, 'Reports Reviewed', ['User reviewed all reports', reasoning])
  end

  def verify_pause_notifications(user_label, pause_notifications)
    verify_historical_event(user_label, 'Monitoring Change', ["User #{pause_notifications ? 'paused' : 'resumed'} notifications for this monitoree"])
  end

  def verify_comment(user_label, comment)
    verify_historical_event(user_label, 'Comment', [comment])
  end

  def verify_historical_event(user_label, event_type, contents)
    email = SystemTestUtils::USERS[user_label]['email']
    assert page.has_content?(email), @@system_test_utils.get_err_msg("History #{event_type}", 'user email', email)
    assert page.has_content?(event_type), @@system_test_utils.get_err_msg("History #{event_type}", 'event type', event_type)
    contents.each do |content|
      assert page.has_content?(content), @@system_test_utils.get_err_msg("History #{event_type}", 'content', content) unless content.nil?
    end
  end
end
