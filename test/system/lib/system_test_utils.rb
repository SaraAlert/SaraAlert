# frozen_string_literal: true

require 'application_system_test_case'

class SystemTestUtils < ApplicationSystemTestCase
  ASSESSMENTS = YAML.safe_load(File.read("#{__dir__}/../form_data/assessments.yml"))
  CONDITIONS = YAML.safe_load(File.read("#{__dir__}/../../fixtures/conditions.yml"))
  MONITOREES = YAML.safe_load(File.read("#{__dir__}/../form_data/monitorees.yml"))
  PATIENTS = YAML.safe_load(File.read("#{__dir__}/../../fixtures/patients.yml"))
  REPORTS = YAML.safe_load(File.read("#{__dir__}/../../fixtures/assessments.yml"))
  SYMPTOMS = YAML.safe_load(File.read("#{__dir__}/../../fixtures/symptoms.yml"))
  USERS = YAML.safe_load(File.read("#{__dir__}/../../fixtures/users.yml"))

  SIGN_IN_URL = '/users/sign_in'
  USER_PASSWORD = '1234567ab!'
  DOWNLOAD_PATH = Rails.root.join('tmp/downloads')

  ENROLLMENT_SUBMISSION_DELAY = 5 # wait for submission alert animation to finish
  ENROLLMENT_PAGE_TRANSITION_DELAY = 1 # wait for carousel animation to finish
  POP_UP_ALERT_ANIMATION_DELAY = 1 # wait for alert to pop up or dismiss
  MODAL_ANIMATION_DELAY = 0.5 # wait for modal to load
  ACCEPT_REJECT_DELAY = 0.01 # wait for UI to update after accepting or rejecting monitoree on import

  def login(user_label)
    visit '/'
    assert_equal(SIGN_IN_URL, page.current_path)
    fill_in 'user_email', with: USERS[user_label]['email']
    fill_in 'user_password', with: USER_PASSWORD
    click_on 'login'
    jurisdiction_id = verify_user_jurisdiction(user_label)
    jurisdiction_id
  end

  def logout
    click_on 'Logout'
  end

  def return_to_dashboard(workflow, is_epi=true)
    if !is_epi
      click_on 'Return To Dashboard'
    elsif !workflow.nil?
      click_on "Return to #{workflow.capitalize} Dashboard"
    else
      click_on 'Return to '
    end
  end

  def go_to_workflow(workflow)
    click_on "#{workflow.capitalize} Monitoring"
  end

  def go_to_tab(tab)
    find("##{tab}-tab").click
  end

  def go_to_next_page(wait=true)
    wait_for_enrollment_page_transition if wait
    click_on 'Next'
  end

  def go_to_prev_page(wait=true)
    wait_for_enrollment_page_transition if wait
    click_on 'Previous'
  end

  def wait_for_enrollment_submission
    sleep(inspection_time = ENROLLMENT_SUBMISSION_DELAY)
  end

  def wait_for_enrollment_page_transition
    sleep(inspection_time = ENROLLMENT_PAGE_TRANSITION_DELAY)
  end

  def wait_for_pop_up_alert
    sleep(inspection_time = POP_UP_ALERT_ANIMATION_DELAY)
  end

  def wait_for_modal_animation
    sleep(inspection_time = MODAL_ANIMATION_DELAY)
  end

  def wait_for_dashboard_load
    sleep(inspection_time = DASHBOARD_LOAD_DELAY)
  end

  def wait_for_accept_reject
    sleep(inspection_time = ACCEPT_REJECT_DELAY)
  end

  def verify_user_jurisdiction(user_label)
    jurisdiction = User.where(email: "#{user_label}@example.com").includes(:jurisdiction).first.jurisdiction
    assert page.has_content?(jurisdiction.name), get_err_msg('Dashboard', 'user jurisdiction', jurisdiction.name) if !user_label.include?('admin')
    jurisdiction.id
  end

  def get_displayed_name(monitoree)
    "#{monitoree['identification']['last_name']}, #{monitoree['identification']['first_name']}"
  end

  def get_err_msg(component, field, value)
    "#{component} - #{field} should be: #{value}"
  end

  def get_assessments
    ASSESSMENTS
  end

  def get_conditions
    CONDITIONS
  end

  def get_monitorees
    MONITOREES
  end

  def get_patients
    PATIENTS
  end

  def get_reports
    REPORTS
  end

  def get_symptoms
    SYMPTOMS
  end

  def get_users
    USERS
  end

  def get_download_path
    DOWNLOAD_PATH
  end

  def get_assessment_name(patient_label, assessment_label)
    "#{patient_label}_assessment_#{assessment_label.to_s}"
  end

  def get_patient_display_name(patient_label)
    "#{PATIENTS[patient_label]['last_name']}, #{PATIENTS[patient_label]['first_name']}"
  end

  def get_monitoree_display_name(monitoree_label)
    "#{MONITOREES[monitoree_label]['identification']['last_name']}, #{MONITOREES[monitoree_label]['identification']['first_name']}"
  end

  def format_date(value)
    "#{value[6..9]}-#{value[0..1]}-#{value[3..4]}"
  end

  def trim_ms_from_date(value)
    Time.parse(value).change(:usec => 0).strftime('%Y-%m-%d %H:%M:%S')
  end

  def calculate_age(value)
    dob = Date.parse(format_date(value))
    now = Time.now.utc.to_date
    now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
  end
end
