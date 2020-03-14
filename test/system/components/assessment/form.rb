require 'application_system_test_case'

require_relative '../../lib/system_test_utils'

class AssessmentForm < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
  
  def complete_assessment(assessment)
    assessments_url = @@system_test_utils.get_assessments_url(assessment['submission_token'])
    visit assessments_url
    assert_equal(assessments_url, page.current_path)
    populate_assessment(assessment['symptoms'])
    assert_selector 'label', text: 'Thank You For Completing Your Self Report'
    ## assert assessment successfully saved to database
  end
  
  def populate_assessment(symptoms)
    symptoms.each { |symptom|
      case symptom['type']
      when 'BoolSymptom'
        find('label', text: symptom['label']).click if symptom['bool_value']
      when 'FloatSymptom'
        fill_in symptom['label'], with: symptom['float_value']
      when 'IntSymptom'
        fill_in symptom['label'], with: symptom['int_value']
      end
    }
    click_on 'Submit'
  end
end