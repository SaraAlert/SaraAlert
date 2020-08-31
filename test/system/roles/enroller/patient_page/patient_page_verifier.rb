# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../enrollment/steps'
require_relative '../../../lib/system_test_utils'

class EnrollerPatientPageVerifier < ApplicationSystemTestCase
  include ImportExport
  @@enrollment_form_steps = EnrollmentFormSteps.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_monitoree_info(monitoree, is_epi: false)
    find('#patient-info-header').click if is_epi
    @@enrollment_form_steps.steps.each do |enrollment_step, enrollment_fields|
      verify_enrollment_step(monitoree[enrollment_step.to_s], enrollment_fields)
    end
  end

  def verify_group_member_info(existing_monitoree, new_monitoree, is_epi: false)
    find('#patient-info-header').click if is_epi
    verify_enrollment_step(new_monitoree['identification'], @@enrollment_form_steps.steps[:identification])
    verify_enrollment_step(existing_monitoree['address'], @@enrollment_form_steps.steps[:address])
    verify_enrollment_step(existing_monitoree['contact_info'], @@enrollment_form_steps.steps[:contact_info])
    verify_enrollment_step(existing_monitoree['arrival_info'], @@enrollment_form_steps.steps[:arrival_info])
    verify_enrollment_step(existing_monitoree['additional_planned_travel'], @@enrollment_form_steps.steps[:additional_planned_travel])
    verify_enrollment_step(existing_monitoree['potential_exposure_info'], @@enrollment_form_steps.steps[:potential_exposure_info])
  end

  def verify_enrollment_step(data, fields)
    return unless data

    fields.each do |field|
      if data[field[:id]] && field[:info_page]
        if %w[text select date].include?(field[:type])
          assert page.has_content?(data[field[:id]]), @@system_test_utils.get_err_msg('Monitoree details', field[:id], data[field[:id]])
        elsif field[:type] == 'phone'
          phone = format_phone_number(data[field[:id]])
          assert page.has_content?(phone), @@system_test_utils.get_err_msg('Monitoree details', field[:id], phone)
        elsif field[:type] == 'age'
          age = @@system_test_utils.calculate_age(data[field[:id]])
          assert page.has_content?(age), @@system_test_utils.get_err_msg('Monitoree details', field[:id], age)
        elsif field[:type] == 'race'
          assert page.has_content?(field[:info_page]), @@system_test_utils.get_err_msg('Monitoree details', field[:info_page], 'present')
        elsif field[:type] == 'checkbox' || field[:type] == 'risk_factor'
          assert page.has_content?(field[:label]), @@system_test_utils.get_err_msg('Monitoree details', field[:label], 'present')
        end
      end
    end
  end
end
