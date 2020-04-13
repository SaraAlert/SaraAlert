# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'history_verifier'
require_relative '../system_test_utils'

class PublicHealthMonitoringActions < ApplicationSystemTestCase
  @@public_health_monitoring_history_verifier = PublicHealthMonitoringHistoryVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def update_monitoring_status(user_name, monitoring_status, status_change_reason, reasoning)
    if monitoring_status != find('#monitoring_status')['value']
      select monitoring_status, from: 'monitoring_status'
      select status_change_reason, from: 'monitoring_status_option'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_monitoring_status(user_name, monitoring_status, status_change_reason, reasoning)
    end
  end

  def update_exposure_risk_assessment(user_name, exposure_risk_assessment, reasoning)
    if exposure_risk_assessment != find('#exposure_risk_assessment')['value']
      select exposure_risk_assessment, from: 'exposure_risk_assessment'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_exposure_risk_assessment(user_name, exposure_risk_assessment, reasoning)
    end
  end

  def update_monitoring_plan(user_name, monitoring_plan, reasoning)
    if monitoring_plan != find('#monitoring_plan')['value']
      select monitoring_plan, from: 'monitoring_plan'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_monitoring_plan(user_name, monitoring_plan, reasoning)
    end
  end

  def update_latest_public_health_action(user_name, latest_public_health_action, reasoning)
    if latest_public_health_action != find('#public_health_action')['value']
      select latest_public_health_action, from: 'public_health_action'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_latest_public_health_action(user_name, latest_public_health_action, reasoning)
    end
  end

  def add_additional_public_health_action(user_name, reasoning, submit=true)
    button = find('#public_health_action').first(:xpath, './/..//..').find(:css, 'button.btn-lg.btn-square.btn.btn-primary')
    if find('#public_health_action')['value'] == 'None'
      button.hover
      assert page.has_content?('You can\'t add an additional "None" public health action'), @@system_test_utils.get_err_msg('Monitoring actions', 'hover error message', 'existent')
    else
      button.hover
      assert page.has_content?('Add an additional'), @@system_test_utils.get_err_msg('Monitoring actions', 'hover message', 'existent')
      button.click
      if submit
        page.driver.browser.switch_to.alert.accept
        @@public_health_monitoring_history_verifier.verify_additional_public_health_action(user_name)
      else
        page.driver.browser.switch_to.alert.dismiss
      end
    end
  end

  def update_current_workflow(user_name, current_workflow, reasoning)
    if current_workflow != find('#isolation_status')['value']
      select current_workflow, from: 'isolation_status'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_current_workflow(user_name, current_workflow, reasoning)
    end
  end

  def update_assigned_jurisdiction(user_name, jurisdiction, reasoning)
    fill_in 'jurisdictionList', with: jurisdiction
    click_on 'Change Jurisdiction'
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
    @@system_test_utils.wait_for_modal_animation
    @@public_health_monitoring_history_verifier.verify_assigned_jurisdiction(user_name, jurisdiction, reasoning)
  end
end
