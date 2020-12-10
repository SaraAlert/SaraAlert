# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthCustomExport'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthCustomExportTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'export all monitorees with all data types with all fields' do
    settings = {
      selected_records: :all,
      elements: {
        patients: {
          checked: ['Monitoree Details']
        }
      }
    }
    @@public_health_test_helper.export_custom('state1_epi', settings)
  end
end
