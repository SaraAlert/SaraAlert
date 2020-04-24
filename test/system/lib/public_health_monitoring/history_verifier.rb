# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../system_test_utils'

class PublicHealthMonitoringHistoryVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  USERS = @@system_test_utils.get_users

  def verify_monitoring_status(user_label, monitoring_status, status_change_reason, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed monitoring status', monitoring_status, status_change_reason, reasoning])
  end

  def verify_exposure_risk_assessment(user_label, exposure_risk_assessment, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed exposure risk assessment', exposure_risk_assessment, reasoning])
  end

  def verify_monitoring_plan(user_label, monitoring_plan, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed monitoring plan', monitoring_plan, reasoning])
  end

  def verify_latest_public_health_action(user_label, latest_public_health_action, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed latest public health action', latest_public_health_action, reasoning])
  end

  def verify_additional_public_health_action(user_label)
    verify_historical_event(user_label, 'Monitoring Change', ['User added an additional public health action'])
  end

  def verify_current_workflow(user_label, current_workflow, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed workflow', current_workflow, reasoning])
  end

  def verify_assigned_jurisdiction(user_label, jurisdiction, reasoning)
    verify_historical_event(user_label, 'Monitoring Change', ['User changed jurisdiction', jurisdiction, reasoning])
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
    assert page.has_content?(USERS[user_label]['email']), @@system_test_utils.get_err_msg("History #{event_type}", 'user email', USERS[user_label]['email'])
      assert page.has_content?(event_type), @@system_test_utils.get_err_msg("History #{event_type}", 'event type', event_type)
      contents.each { |content|
      assert page.has_content?(content), @@system_test_utils.get_err_msg("History #{event_type}", 'content', content)
    }
  end
end
