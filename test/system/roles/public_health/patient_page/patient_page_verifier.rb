# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../../lib/system_test_utils'

class PublicHealthPatientPageVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def verify_patient_details(patient, workflow)
    sleep(0.5) # wait for any sticky filter to populate so it can be cleared during fill_in
    fill_in('search', with: patient.last_name, fill_options: { clear: :backspace })
    click_on "#{patient.last_name}, #{patient.first_name}"
    find('#details-expander-link').click
    fields = %w[first_name last_name]
    fields.each do |field|
      assert page.has_content?(patient[field]), @@system_test_utils.get_err_msg('Monitoree details', field, patient[field])
    end
    @@system_test_utils.return_to_dashboard(workflow)
  end
end
