require "application_system_test_case"

require_relative "lib/system_test_utils"

class MonitoreeTest < ApplicationSystemTestCase

  @@system_test_utils = SystemTestUtils.new(nil)
  
  ASSESSMENTS = @@system_test_utils.get_assessments
  
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

  test "redirect to log in page if assessment link is visited" do
    visit @@system_test_utils.get_assessments_url("abc")
    assert_equal(@@system_test_utils.get_sign_in_url, page.current_path)
  end

  test "display error message and prevent submission upon invalid temperature input" do
    visit @@system_test_utils.get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    INVALID_TEMPERATURE_NUMBERS = ["abc", "&9$*&@)#(!", "192.849.01", "ab9.3iuj@9"]
    for temperature in INVALID_TEMPERATURE_NUMBERS
      select "No", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Submit", "Please enter a valid number.")
      select "Yes", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Continue", "Please enter a valid number.")
    end
  end
  
  test "display error message and prevent submission upon out of bounds temperature input" do
    visit @@system_test_utils.get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    OUT_OF_BOUNDS_TEMPERATURES = ["195 381", "-158", "842910", "50", "-1", "130"]
    for temperature in OUT_OF_BOUNDS_TEMPERATURES
      select "No", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Submit", "Temperature Out of Bounds [27 - 49C] [80 - 120F]")
      select "Yes", from: "experiencing_symptoms"
      populate_temperature_with_invalid_input(temperature, "Continue", "Temperature Out of Bounds [27 - 49C] [80 - 120F]")
    end
  end

  test "maintain form data after clicking continue and previous" do
    visit @@system_test_utils.get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    temperature = "100"
    fill_in "temperature", with: temperature
    select "Yes", from: "experiencing_symptoms"
    click_on "Continue"
    @@system_test_utils.wait_for_checkbox_animation
    click_on "Previous"
    assert_equal(temperature, find("#temperature")["value"])
  end

  test "maintain form data after clicking continue and previous and submit successfully" do
    visit @@system_test_utils.get_assessments_url(ASSESSMENTS["assessment_1"]["submission_token"])
    temperature = "98"
    fill_in "temperature", with: temperature
    select "No", from: "experiencing_symptoms"
    select "Yes", from: "experiencing_symptoms"
    click_on "Continue"
    @@system_test_utils.wait_for_checkbox_animation
    find("label", text: "Difficulty Breathing").click
    find("label", text: "Difficulty Breathing").click
    click_on "Previous"
    assert_equal(temperature, find("#temperature")["value"])
    click_on "Continue"
    @@system_test_utils.wait_for_checkbox_animation
    find("label", text: "Difficulty Breathing").click
    click_on "Submit"
    assert_selector "label", text: "Thank You For Completing Your Self Report"
  end

  def complete_assessment(assessment)
    assessments_url = @@system_test_utils.get_assessments_url(assessment["submission_token"])
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
    assert_selector "label", text: "Thank You For Completing Your Self Report"
    ## assert assessment successfully saved to database
  end

  def populate_symptoms(assessment)
    assert_selector "button", text: "Previous"
    if assessment["cough"]
      @@system_test_utils.wait_for_checkbox_animation
      find("label", text: "Cough").click
    end
    if assessment["difficulty_breathing"]
      @@system_test_utils.wait_for_checkbox_animation
      find("label", text: "Difficulty Breathing").click
    end
  end

  def populate_temperature_with_invalid_input(temperature, button_text, error_msg)
    fill_in "temperature", with: temperature
    assert_selector "#submit_button", text: button_text
    click_on button_text
    assert_selector "div", text: error_msg
    assert_selector "div", text: "What was your temperature today?"
  end

end
