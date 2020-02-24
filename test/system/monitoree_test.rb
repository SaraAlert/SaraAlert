require "application_system_test_case"

class MonitoreeTest < ApplicationSystemTestCase

  ASSESSMENTS = YAML.load(File.read(__dir__ + "/form_data/assessments.yml"))
  
  SIGN_IN_URL = "/users/sign_in"

  TEMPERATURE_INPUT_TEXT = "What was your temperature today?"
  SUCCESSFUL_SUBMISSION_TEXT = "Thank You For Completing Your Self Report"

  INVALID_TEMPERATURE_NUMBER_ERROR_MSG = "Please enter a valid number."
  OUT_OF_BOUNDS_TEMPERATURE_ERROR_MSG = "Temperature Out of Bounds [27 - 49C] [80 - 120F]"

  CHECKBOX_ANIMATION_LOAD_DELAY = 0.5 # TODO: find a better way to wait for checkbox to load
  
  test "should redirect to log in page if assessment link is visited" do
    invalid_submission_token = "abc"
    visit get_assessments_url(invalid_submission_token)
    assert_equal(SIGN_IN_URL, page.current_path)
  end

  test "should display error message and prevent submission upon invalid temperature input" do
    visit get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    INVALID_TEMPERATURE_NUMBERS = ["abc", "&9$*&@)#(!", "192.849.01", "ab9.3iuj@9"]
    for temperature in INVALID_TEMPERATURE_NUMBERS
      select "No", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Submit", INVALID_TEMPERATURE_NUMBER_ERROR_MSG)
      select "Yes", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Continue", INVALID_TEMPERATURE_NUMBER_ERROR_MSG)
    end
  end
  
  test "should display error message and prevent submission upon out of bounds temperature input" do
    visit get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    OUT_OF_BOUNDS_TEMPERATURES = ["195 381", "-158", "842910", "50", "-1", "130"]
    for temperature in OUT_OF_BOUNDS_TEMPERATURES
      select "No", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Submit", OUT_OF_BOUNDS_TEMPERATURE_ERROR_MSG)
      select "Yes", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Continue", OUT_OF_BOUNDS_TEMPERATURE_ERROR_MSG)
    end
  end

  test "should maintain form data after clicking continue and previous" do
    visit get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    temperature = "100"
    fill_in "temperature", with: temperature
    select "Yes", from: "experiencing_symptoms"
    click_on "Continue"
    sleep(inspection_time = CHECKBOX_ANIMATION_LOAD_DELAY)
    click_on "Previous"
    assert_equal(temperature, find("#temperature")["value"])
  end

  test "should maintain form data after clicking continue and previous and submit successfully" do
    visit get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    temperature = "98"
    fill_in "temperature", with: temperature
    select "No", from: "experiencing_symptoms"
    select "Yes", from: "experiencing_symptoms"
    click_on "Continue"
    sleep(inspection_time = CHECKBOX_ANIMATION_LOAD_DELAY)
    find("label", text: "Difficulty Breathing").click
    find("label", text: "Difficulty Breathing").click
    click_on "Previous"
    assert_equal(temperature, find("#temperature")["value"])
    click_on "Continue"
    sleep(inspection_time = CHECKBOX_ANIMATION_LOAD_DELAY)
    find("label", text: "Difficulty Breathing").click
    click_on "Submit"
    assert_selector "label", text: SUCCESSFUL_SUBMISSION_TEXT
  end

  test "complete assessment without symptoms" do
    complete_assessment(ASSESSMENTS["assessment_1"])
  end
  
  test "complete assessment with cough" do
    complete_assessment(ASSESSMENTS["assessment_2"])
  end

  test "complete assessment with difficulty breathing" do
    complete_assessment(ASSESSMENTS["assessment_3"])
  end

  test "complete assessment with cough and difficulty breathing" do
    complete_assessment(ASSESSMENTS["assessment_4"])
  end

  def complete_assessment(assessment)
    assessments_url = get_assessments_url(assessment["submission_token"])
    visit assessments_url
    assert_equal(assessments_url, page.current_path)
    fill_in "temperature", with: assessment["temperature"]
    if assessment["experiencing_symptoms"]
      select "Yes", from: "experiencing_symptoms"
      assert_selector "#submit_button", text: "Continue"
      click_on "Continue"
      populate_symptoms(assessment)
    else
      select "No", from: "experiencing_symptoms"
      assert_selector "#submit_button", text: "Submit"
    end
    assert_selector "button", text: "Submit"
    click_on "Submit"
    assert_selector "label", text: SUCCESSFUL_SUBMISSION_TEXT
    # TODO: assert assessment successfully saved to database
  end

  def populate_symptoms(assessment)
    assert_selector "button", text: "Previous"
    if assessment["cough"]
      sleep(inspection_time = CHECKBOX_ANIMATION_LOAD_DELAY)
      find("label", text: "Cough").click
    end
    if assessment["difficulty_breathing"]
      sleep(inspection_time = CHECKBOX_ANIMATION_LOAD_DELAY)
      find("label", text: "Difficulty Breathing").click
    end
  end

  def populate_temperature_with_invalid_input(temperature, button_text, error_msg)
    fill_in "temperature", with: temperature
    assert_selector "#submit_button", text: button_text
    click_on button_text
    assert_selector "div", text: error_msg
    assert_selector "div", text: TEMPERATURE_INPUT_TEXT
  end

  def get_assessments_url(submission_token)
    "/patients/" + submission_token + "/assessments/new"
  end

end
