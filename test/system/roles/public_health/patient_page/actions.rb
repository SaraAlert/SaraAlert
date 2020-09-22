# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'history_verifier'
require_relative '../../../lib/system_test_utils'

class PublicHealthPatientPageActions < ApplicationSystemTestCase
  @@public_health_patient_page_history_verifier = PublicHealthPatientPageHistoryVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  # rubocop:disable Metrics/ParameterLists
  def update_monitoring_status(user_label, patient_label, monitoring_status, monitoring_reason, reasoning)
    return unless monitoring_status != find('#monitoring_status')['value']

    select monitoring_status, from: 'monitoring_status'
    select monitoring_reason, from: 'monitoring_reason' if monitoring_reason && monitoring_status == 'Not Monitoring'
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
    @@system_test_utils.wait_for_modal_animation
    @@public_health_patient_page_history_verifier.verify_monitoring_status(user_label, monitoring_status, monitoring_reason, reasoning)
    patient = @@system_test_utils.get_patient_by_label(patient_label)
    assert_equal true, patient[:monitoring] if monitoring_status == 'Actively Monitoring'
    assert [false, nil].include?(patient[:monitoring]) if monitoring_status == 'Not Monitoring'
    assert_equal monitoring_reason, patient[:monitoring_reason] if monitoring_reason && monitoring_status == 'Not Monitoring'
  end

  def update_exposure_risk_assessment(user_label, patient_label, exposure_risk_assessment, reasoning)
    return unless exposure_risk_assessment != find('#exposure_risk_assessment')['value']

    select exposure_risk_assessment, from: 'exposure_risk_assessment'
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
    @@system_test_utils.wait_for_modal_animation
    @@public_health_patient_page_history_verifier.verify_exposure_risk_assessment(user_label, exposure_risk_assessment, reasoning)
    assert_equal exposure_risk_assessment, @@system_test_utils.get_patient_by_label(patient_label)[:exposure_risk_assessment]
  end

  def update_monitoring_plan(user_label, patient_label, monitoring_plan, reasoning)
    return unless monitoring_plan != find('#monitoring_plan')['value']

    select monitoring_plan, from: 'monitoring_plan'
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
    @@system_test_utils.wait_for_modal_animation
    @@public_health_patient_page_history_verifier.verify_monitoring_plan(user_label, monitoring_plan, reasoning)
    assert_equal monitoring_plan, @@system_test_utils.get_patient_by_label(patient_label)[:monitoring_plan]
  end

  def update_latest_public_health_action(user_label, patient_label, latest_public_health_action, reasoning)
    return unless latest_public_health_action != find('#public_health_action')['value']

    select latest_public_health_action, from: 'public_health_action'
    fill_in 'reasoning', with: reasoning
    click_on 'Submit'
    @@system_test_utils.wait_for_modal_animation
    @@public_health_patient_page_history_verifier.verify_latest_public_health_action(user_label, latest_public_health_action, reasoning)
    assert_equal latest_public_health_action, @@system_test_utils.get_patient_by_label(patient_label)[:public_health_action]
  end

  def update_assigned_jurisdiction(user_label, patient_label, jurisdiction, reasoning, valid_jurisdiction: true, under_hierarchy: true)
    assert page.has_button?('Change Jurisdiction', disabled: true)
    fill_in 'jurisdictionId', with: jurisdiction
    if valid_jurisdiction
      assert page.has_button?('Change Jurisdiction', disabled: false)
      click_on 'Change Jurisdiction'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      if under_hierarchy
        assert page.has_button?('Change Jurisdiction', disabled: true)
        @@public_health_patient_page_history_verifier.verify_assigned_jurisdiction(user_label, jurisdiction, reasoning)
        assert_equal jurisdiction, @@system_test_utils.get_patient_by_label(patient_label).jurisdiction[:path].to_s
      end
    else
      assert page.has_button?('Change Jurisdiction', disabled: true)
    end
  end

  def update_assigned_user(user_label, patient_label, assigned_user, reasoning, valid_assigned_user: true, changed: true)
    assert page.has_button?('Change User', disabled: true)
    fill_in 'assignedUser', with: assigned_user
    if valid_assigned_user && changed
      assert page.has_button?('Change User', disabled: false)
      click_on 'Change User'
      fill_in 'reasoning', with: reasoning
      click_on 'Submit'
      @@system_test_utils.wait_for_modal_animation
      assert page.has_button?('Change User', disabled: true)
      @@public_health_patient_page_history_verifier.verify_assigned_user(user_label, assigned_user, reasoning)
      assert_equal assigned_user, @@system_test_utils.get_patient_by_label(patient_label)[:assigned_user].to_s
    elsif valid_assigned_user && !changed
      assert page.has_button?('Change User', disabled: true)
    elsif !valid_assigned_user && changed
      assert_not_equal(assigned_user, page.find_field('assignedUser').value)
    end
  end
  # rubocop:enable Metrics/ParameterLists
end
