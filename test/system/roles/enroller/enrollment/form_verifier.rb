# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'form'
require_relative 'steps'
require_relative '../../../lib/system_test_utils'

class EnrollmentFormVerifier < ApplicationSystemTestCase
  @@enrollment_form = EnrollmentForm.new(nil)
  @@enrollment_form_steps = EnrollmentFormSteps.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_form_data_after_navigation(monitoree)
    click_link 'Enroll New Monitoree'
    @@enrollment_form_steps.steps.each_key do |step|
      @@enrollment_form.populate_enrollment_step(step, monitoree[step.to_s])
      @@system_test_utils.go_to_prev_page
      verify_form_data_consistency_for_step(step, monitoree[step.to_s])
      @@system_test_utils.go_to_next_page
    end
  end

  def verify_form_data_consistency_for_step(step, data)
    return unless data

    @@enrollment_form_steps.steps[step].each do |field|
      next unless data[field[:id]]

      click_on field[:tab] if field[:tab]
      if %w[text select date].include?(field[:type])
        assert_equal(data[field[:id]], find("##{field[:id]}")['value'], "#{field[:id]} mismatch")
      elsif field[:tab] == 'phone'
        assert_equal(data[field[:id]], Phonelib.parse(find("##{field[:id]}")['value']).full_e164, "#{field[:id]} mismatch")
      elsif %w[checkbox race risk_factor].include?(field[:type])
        # figure out how to get value of checkbox input from DOM
      end
    end
  end

  def verify_home_address_copied(monitoree)
    @@enrollment_form_steps.steps[:address].each do |field|
      assert_equal(monitoree['address'][field[:id]], find("#monitored_#{field[:id]}")['value']) if field[:copiable]
    end
  end
end
