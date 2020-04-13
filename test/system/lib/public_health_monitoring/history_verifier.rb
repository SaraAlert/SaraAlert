# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../system_test_utils'

class PublicHealthMonitoringHistoryVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  USERS = @@system_test_utils.get_users

  def verify_monitoring_status(user_name, monitoring_status, status_change_reason, reasoning)
    verify_historical_event(user_name, 'Monitoring Change', ['User changed monitoring status', monitoring_status, status_change_reason, reasoning])
  end

  def verify_exposure_risk_assessment(user_name, exposure_risk_assessment, reasoning)
    verify_historical_event(user_name, 'Monitoring Change', ['User changed exposure risk assessment', exposure_risk_assessment, reasoning])
  end

  def verify_monitoring_plan(user_name, monitoring_plan, reasoning)
    verify_historical_event(user_name, 'Monitoring Change', ['User changed monitoring plan', monitoring_plan, reasoning])
  end

  def verify_latest_public_health_action(user_name, latest_public_health_action, reasoning)
    verify_historical_event(user_name, 'Monitoring Change', ['User changed latest public health action', latest_public_health_action, reasoning])
  end

  def verify_additional_public_health_action(user_name)
    verify_historical_event(user_name, 'Monitoring Change', ['User added an additional public health action'])
  end

  def verify_current_workflow(user_name, current_workflow, reasoning)
    verify_historical_event(user_name, 'Monitoring Change', ['User changed workflow', current_workflow, reasoning])
  end

  def verify_assigned_jurisdiction(user_name, jurisdiction, reasoning)
    verify_historical_event(user_name, 'Monitoring Change', ['User changed jurisdiction', jurisdiction, reasoning])
  end

  def verify_add_report(user_name)
    verify_historical_event(user_name, 'Report Created', ['User created a new subject report'])
  end

  def verify_edit_report(user_name)
    verify_historical_event(user_name, 'Report Updated', ['User updated an existing subject report'])
  end

  def verify_add_note_to_report(user_name, assessment_id, note)
    verify_historical_event(user_name, 'Report Note', ['User left a note for a report', assessment_id, note])
  end

  def verify_mark_all_as_reviewed(user_name, reasoning)
    verify_historical_event(user_name, 'Reports Reviewed', ['User reviewed all reports', reasoning])
  end

  def verify_pause_notifications(user_name, pause_notifications)
    verify_historical_event(user_name, 'Monitoring Change', ["User #{pause_notifications ? 'paused' : 'resumed'} notifications for this monitoree"])
  end

  def verify_comment(user_name, comment)
    verify_historical_event(user_name, 'Comment', [comment])
  end

  def verify_historical_event(user_name, event_type, contents)
    assert page.has_content?(USERS[user_name]['email']), @@system_test_utils.get_err_msg("History #{event_type}", 'user email', USERS[user_name]['email'])
      assert page.has_content?(event_type), @@system_test_utils.get_err_msg("History #{event_type}", 'event type', event_type)
      contents.each { |content|
      assert page.has_content?(content), @@system_test_utils.get_err_msg("History #{event_type}", 'content', content)
    }
  end
end
