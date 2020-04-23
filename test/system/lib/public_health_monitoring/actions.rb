# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'history_verifier'
require_relative '../system_test_utils'

class PublicHealthMonitoringActions < ApplicationSystemTestCase
  @@public_health_monitoring_history_verifier = PublicHealthMonitoringHistoryVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def update_monitoring_status(user_label, monitoring_status, status_change_reason, reasoning)
    if monitoring_status != find('#monitoring_status')['value']
      select monitoring_status, from: 'monitoring_status'
      select status_change_reason, from: 'monitoring_status_option'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_monitoring_status(user_label, monitoring_status, status_change_reason, reasoning)
    end
  end

  def update_exposure_risk_assessment(user_label, exposure_risk_assessment, reasoning)
    if exposure_risk_assessment != find('#exposure_risk_assessment')['value']
      select exposure_risk_assessment, from: 'exposure_risk_assessment'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_exposure_risk_assessment(user_label, exposure_risk_assessment, reasoning)
    end
  end

  def update_monitoring_plan(user_label, monitoring_plan, reasoning)
    if monitoring_plan != find('#monitoring_plan')['value']
      select monitoring_plan, from: 'monitoring_plan'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_monitoring_plan(user_label, monitoring_plan, reasoning)
    end
  end

  def update_latest_public_health_action(user_label, latest_public_health_action, reasoning)
    if latest_public_health_action != find('#public_health_action')['value']
      select latest_public_health_action, from: 'public_health_action'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_latest_public_health_action(user_label, latest_public_health_action, reasoning)
    end
  end

  def add_additional_public_health_action(user_label, reasoning, submit=true)
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
        @@public_health_monitoring_history_verifier.verify_additional_public_health_action(user_label)
      else
        page.driver.browser.switch_to.alert.dismiss
      end
    end
  end

  def update_current_workflow(user_label, current_workflow, reasoning)
    if current_workflow != find('#isolation_status')['value']
      select current_workflow, from: 'isolation_status'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      @@public_health_monitoring_history_verifier.verify_current_workflow(user_label, current_workflow, reasoning)
    end
  end

  def update_assigned_jurisdiction(user_label, jurisdiction, reasoning, valid_jurisdiction=true, under_hierarchy=true)
    assert page.has_button?('Change Jurisdiction', disabled: true)
    fill_in 'jurisdictionList', with: jurisdiction
    if valid_jurisdiction
      assert page.has_button?('Change Jurisdiction', disabled: false)
      click_on 'Change Jurisdiction'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      if under_hierarchy
        assert page.has_button?('Change Jurisdiction', disabled: true)
        @@public_health_monitoring_history_verifier.verify_assigned_jurisdiction(user_label, jurisdiction, reasoning)
      end
    else
      assert page.has_button?('Change Jurisdiction', disabled: true)
    end
  end
end
