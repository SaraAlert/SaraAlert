require "application_system_test_case"

class PublicHealthMonitoringUtils < ApplicationSystemTestCase

  SIGN_IN_URL = "/users/sign_in"
  USER_PASSWORD = "123456ab"

  CHECKBOX_ANIMATION_DELAY = 0.4
  MODAL_ANIMATION_DELAY = 1
  
  def login(user)
    visit "/"
    assert_equal(SIGN_IN_URL, page.current_path)
    fill_in "user_email", with: user["email"]
    fill_in "user_password", with: USER_PASSWORD
    click_on "login"
  end

  def wait_for_checkbox_animation
    sleep(inspection_time = CHECKBOX_ANIMATION_DELAY)
  end
  
  def wait_for_modal_animation
    sleep(inspection_time = MODAL_ANIMATION_DELAY)
  end

end