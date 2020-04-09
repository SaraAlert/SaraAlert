# frozen_string_literal: true

require 'application_system_test_case'

class SystemTestUtils < ApplicationSystemTestCase
  ASSESSMENTS = YAML.safe_load(File.read(__dir__ + '/../form_data/assessments.yml'))
  CONDITIONS = YAML.safe_load(File.read(__dir__ + '/../../fixtures/conditions.yml'))
  MONITOREES = YAML.safe_load(File.read(__dir__ + '/../form_data/monitorees.yml'))
  PATIENTS = YAML.safe_load(File.read(__dir__ + '/../../fixtures/patients.yml'))
  REPORTS = YAML.safe_load(File.read(__dir__ + '/../../fixtures/assessments.yml'))
  SYMPTOMS = YAML.safe_load(File.read(__dir__ + '/../../fixtures/symptoms.yml'))
  USERS = YAML.safe_load(File.read(__dir__ + '/../../fixtures/users.yml'))

  SIGN_IN_URL = '/users/sign_in'
  USER_PASSWORD = '123456ab'

  ENROLLMENT_SUBMISSION_DELAY = 5 # wait for submission alert animation to finish
  ENROLLMENT_PAGE_TRANSITION_DELAY = 1 # wait for carousel animation to finish loading
  POP_UP_ALERT_ANIMATION_DELAY = 1 # wait for alert to pop up or dismiss
  CHECKBOX_ANIMATION_DELAY = 1 # wait for checkbox to load
  DASHBOARD_LOAD_DELAY = 2 # wait for dashboard to load saved tab

  def login(user_name)
    visit '/'
    assert_equal(SIGN_IN_URL, page.current_path)
    fill_in 'user_email', with: USERS[user_name]['email']
    fill_in 'user_password', with: USER_PASSWORD
    click_on 'login'
    wait_for_dashboard_load
  end

  def login_with_custom_password(email, password)
    visit '/'
    assert_equal(SIGN_IN_URL, page.current_path)
    fill_in 'user_email', with: email
    fill_in 'user_password', with: password
    click_on 'login'
  end

  def logout
    click_on 'Logout'
  end

  def return_to_dashboard
    visit '/'
    wait_for_dashboard_load
  end

  def go_to_next_page
    wait_for_enrollment_page_transition
    click_on 'Next'
  end

  def go_to_prev_page
    wait_for_enrollment_page_transition
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

  def wait_for_checkbox_animation
    sleep(inspection_time = CHECKBOX_ANIMATION_DELAY)
  end

  def wait_for_dashboard_load
    sleep(inspection_time = DASHBOARD_LOAD_DELAY)
  end

  def get_dashboard_display_name(monitoree)
    monitoree['identification']['last_name'] + ', ' + monitoree['identification']['first_name']
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

  def get_sign_in_url
    SIGN_IN_URL
  end

  def get_assessments_url(submission_token)
    '/patients/' + submission_token + '/assessments/new'
  end

  def get_assessment_name(patient_name, report_number)
    patient_name + '_assessment_' + report_number.to_s
  end

  def get_patient_display_name(patient_name)
    PATIENTS[patient_name]['last_name'] + ', ' + PATIENTS[patient_name]['first_name']
  end

  def format_date(value)
    value[6..9] + '-' + value[0..1] + '-' + value[3..4]
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
