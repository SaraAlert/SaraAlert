require 'application_system_test_case'

require_relative '../../lib/system_test_utils'

class AssessmentForm < ApplicationSystemTestCase

  @@system_test_utils = SystemTestUtils.new(nil)
  
  def populate_assessment(id, temperature, cough, difficulty_breathing)
    fill_in 'temperature' + id, with: temperature
      if cough || difficulty_breathing
      select 'Yes', from: 'experiencing_symptoms' + id
      assert_selector '#submit_button', text: 'Continue'
      click_on 'Continue'
      populate_symptoms(cough, difficulty_breathing)
    else
      select 'No', from: 'experiencing_symptoms' + id
      assert_selector '#submit_button', text: 'Submit'
    end
    assert_selector 'button', text: 'Submit'
    click_on 'Submit'
  end

  def populate_symptoms(cough, difficulty_breathing)
    assert_selector 'button', text: 'Previous'
    if cough
      @@system_test_utils.wait_for_checkbox_animation
      find('label', text: 'Cough').click
    end
    if difficulty_breathing
      @@system_test_utils.wait_for_checkbox_animation
      find('label', text: 'Difficulty Breathing').click
    end
  end

  def populate_temperature_with_invalid_input(temperature, button_text, error_msg)
    fill_in 'temperature', with: temperature
    assert_selector '#submit_button', text: button_text
    click_on button_text
    assert_selector 'div', text: error_msg
    assert_selector 'div', text: 'What was your temperature today?'
  end

end