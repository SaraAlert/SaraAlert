# frozen_string_literal: true

require 'application_system_test_case'

class SystemTestUtils < ApplicationSystemTestCase
  ASSESSMENTS = YAML.safe_load(File.read("#{__dir__}/../form_data/assessments.yml"))
  MONITOREES = YAML.safe_load(File.read("#{__dir__}/../form_data/monitorees.yml"))
  PATIENTS = YAML.safe_load(File.read("#{__dir__}/../../fixtures/patients.yml"))
  USERS = YAML.safe_load(File.read("#{__dir__}/../../fixtures/users.yml"))

  SIGN_IN_URL = '/users/sign_in'
  USER_PASSWORD = '1234567ab!'
  DOWNLOAD_PATH = Rails.root.join('tmp/downloads')

  ENROLLMENT_SUBMISSION_DELAY = 5 # wait for submission alert animation to finish
  ENROLLMENT_PAGE_TRANSITION_DELAY = 1 # wait for carousel animation to finish
  POP_UP_ALERT_ANIMATION_DELAY = 1 # wait for alert to pop up or dismiss
  MODAL_ANIMATION_DELAY = 0.5 # wait for modal to load

  def login(user_label)
    visit '/'
    assert_equal(SIGN_IN_URL, page.current_path)
    fill_in 'user_email', with: USERS[user_label]['email']
    fill_in 'user_password', with: USER_PASSWORD
    click_on 'login'
    verify_user_jurisdiction(user_label)
  end

  def logout
    click_on 'Logout'
  end

  def return_to_dashboard(workflow, is_epi: true)
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
    find("##{tab}_tab").click
  end

  def go_to_next_page(wait: true)
    wait_for_enrollment_page_transition if wait
    click_on 'Next'
  end

  def go_to_prev_page(wait: true)
    wait_for_enrollment_page_transition if wait
    click_on 'Previous'
  end

  def verify_user_jurisdiction(user_label)
    jurisdiction = get_user(user_label).jurisdiction
    assert page.has_content?(jurisdiction.name), get_err_msg('Dashboard', 'user jurisdiction', jurisdiction.name) unless user_label.include?('admin')
    jurisdiction.id
  end

  def get_user(user_label)
    User.where(email: "#{user_label}@example.com").includes(:jurisdiction).first
  end

  def get_displayed_name(monitoree)
    "#{monitoree['identification']['last_name']}, #{monitoree['identification']['first_name']}"
  end

  def get_err_msg(component, field, value)
    "#{component} - #{field} should be: #{value}"
  end

  def get_assessment_name(patient_label, assessment_label)
    "#{patient_label}_assessment_#{assessment_label}"
  end

  def get_patient_by_label(patient_label)
    return Patient.where(id: PATIENTS[patient_label]['id']).first if PATIENTS[patient_label]
    return Patient.where(email: MONITOREES[patient_label]['contact_info']['email']).first if MONITOREES[patient_label]
  end

  def get_patient_display_name(patient_label)
    "#{PATIENTS[patient_label]['last_name']}, #{PATIENTS[patient_label]['first_name']}"
  end

  def get_monitoree_display_name(monitoree_label)
    "#{MONITOREES[monitoree_label]['identification']['last_name']}, #{MONITOREES[monitoree_label]['identification']['first_name']}"
  end

  def calculate_age(value)
    dob = Date.parse("#{value[6..9]}-#{value[0..1]}-#{value[3..4]}")
    now = Time.now.utc.to_date
    now.year - dob.year - (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
  end

  def wait_for_enrollment_submission
    sleep(ENROLLMENT_SUBMISSION_DELAY)
  end

  def wait_for_enrollment_page_transition
    sleep(ENROLLMENT_PAGE_TRANSITION_DELAY)
  end

  def wait_for_pop_up_alert
    sleep(POP_UP_ALERT_ANIMATION_DELAY)
  end

  def wait_for_modal_animation
    sleep(MODAL_ANIMATION_DELAY)
  end

  def assessments
    ASSESSMENTS
  end

  def monitorees
    MONITOREES
  end

  def patients
    PATIENTS
  end

  def users
    USERS
  end

  def download_path
    DOWNLOAD_PATH
  end
end
