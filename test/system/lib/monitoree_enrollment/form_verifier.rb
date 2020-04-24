# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'form'
require_relative 'steps'
require_relative '../system_test_utils'

class MonitoreeEnrollmentFormVerifier < ApplicationSystemTestCase
  @@monitoree_enrollment_form = MonitoreeEnrollmentForm.new(nil)
  @@monitoree_enrollment_steps = MonitoreeEnrollmentSteps.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_form_data_after_navigation(monitoree)
    click_link 'Enroll New Monitoree'
    @@monitoree_enrollment_steps.steps.each do |step, fields|
      @@monitoree_enrollment_form.populate_enrollment_step(step, monitoree[step.to_s])
      @@system_test_utils.go_to_prev_page
      verify_form_data_consistency_for_step(step, monitoree[step.to_s])
      @@system_test_utils.go_to_next_page
    end
  end

  def verify_form_data_consistency_for_step(step, data)
    if data
      @@monitoree_enrollment_steps.steps[step].each { |field|
        if data[field[:id]]
          click_on field[:tab] if field[:tab]
          if field[:type] == 'text' || field[:type] == 'select'
            assert_equal(data[field[:id]], find("##{field[:id]}")['value'], "#{field[:id]} mismatch")
          elsif field[:type] == 'date'
            assert_equal(@@system_test_utils.format_date(data[field[:id]]), find("##{field[:id]}")['value'], "#{field[:id]} mismatch")
          elsif field[:type] == 'checkbox' || field[:type] == 'race' || field[:type] == 'risk factor'
            # figure out how to get value of checkbox input from DOM
          end
        end
      }
    end
  end

  def verify_home_address_copied(monitoree)
    @@monitoree_enrollment_steps.steps[:address].each { |field|
      if field[:copiable]
        assert_equal(monitoree['address'][field[:id]], find("#monitored_#{field[:id]}")['value'])
      end
    }
  end
end
