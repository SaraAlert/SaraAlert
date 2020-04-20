# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'steps'
require_relative '../system_test_utils'

class MonitoreeEnrollmentForm < ApplicationSystemTestCase
  @@monitoree_enrollment_steps = MonitoreeEnrollmentSteps.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)
  
  def populate_monitoree_info(monitoree)
    @@monitoree_enrollment_steps.steps.each do |step, fields|
      populate_enrollment_step(step, monitoree[step.to_s])
    end
  end

  def edit_monitoree_info(monitoree)
    click_on '(edit details)'
    @@monitoree_enrollment_steps.steps.each do |step, fields|
      find('h5', text: step.to_s.split('_').map(&:capitalize).join(' ')).first(:xpath, './/..//..').click_on('Edit')
      populate_enrollment_step(step, monitoree[step.to_s])
      @@system_test_utils.wait_for_enrollment_page_transition
    end
  end

  def populate_enrollment_step(step, data, continue=true)
    if data
      @@monitoree_enrollment_steps.steps[step].each { |field|
        if data[field[:id]]
          click_on field[:tab] if field[:tab]
          if field[:type] == 'text' || field[:type] == 'date'
            fill_in field[:id], with: data[field[:id]]
          elsif field[:type] == 'select'
            select data[field[:id]], from: field[:id]
          elsif field[:type] == 'checkbox' || field[:type] == 'race' || field[:type] == 'risk factor'
            find('label', text: field[:label]).click
          end
        end
      }
    end
    @@system_test_utils.go_to_next_page if continue
  end
end
