# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'steps'
require_relative '../../../lib/system_test_utils'

class EnrollmentForm < ApplicationSystemTestCase
  @@enrollment_form_steps = EnrollmentFormSteps.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def populate_monitoree_info(monitoree)
    @@enrollment_form_steps.steps.each_key do |step|
      populate_enrollment_step(step, monitoree[step.to_s])
    end
  end

  def edit_monitoree_info(monitoree)
    find('#details-expander-link').click
    @@enrollment_form_steps.steps.each_key do |step|
      next unless monitoree[step.to_s]

      begin
        click_on "edit-#{step}-btn"
      rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::ElementNotInteractableError
        find('#details-expander-link').click
        click_on "edit-#{step}-btn"
      end
      populate_enrollment_step(step, monitoree[step.to_s])
      @@system_test_utils.wait_for_enrollment_page_transition
    end
  end

  def populate_enrollment_step(step, data, continue: true)
    jurisdiction_change = false
    if data
      @@enrollment_form_steps.steps[step].each do |field|
        next unless data[field[:id]]

        click_on field[:tab] if field[:tab]
        if %i[text date phone].include?(field[:type])
          fill_in field[:id], with: data[field[:id]]
        elsif field[:type] == :select
          select data[field[:id]], from: field[:id]
        elsif field[:type] == :checkbox || field[:type] == :race
          page.find('label', text: field[:label]).click
        elsif field[:type] == :risk_factor
          page.find('label', text: field[:label].upcase).click
        elsif field[:type] == :react_select
          # rubocop:disable Rails/DynamicFindBy
          input_element = page.find_by_id("#{field[:id]}_wrapper").first(:xpath, './/div//div//div//div//div//input')
          # rubocop:enable Rails/DynamicFindBy
          input_element.set data[field[:id]]
          input_element.send_keys :enter
        elsif field[:type] == :recent_date && data[field[:id]]
          fill_in field[:id], with: data[field[:id]].days.ago.strftime('%m/%d/%Y')
        elsif field[:type] == :button
          click_on field[:label]
          @@system_test_utils.wait_for_modal_animation
        end
        jurisdiction_change = true if field[:id] == 'jurisdiction_id'
      end
    end
    @@system_test_utils.go_to_next_page if continue
    click_on 'OK' if jurisdiction_change
  end
end
