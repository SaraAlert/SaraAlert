# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthBulkEdit'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'bulk edit case status from exposure to isolation' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_1 patient_2], :exposure, 'all', 'Confirmed',
                                                             'Continue Monitoring in Isolation Workflow', false)
  end

  test 'bulk edit case status from exposure to closed' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_1 patient_2], :exposure, 'all', 'Confirmed', 'End Monitoring', false)
  end

  test 'bulk edit case status from isolation to exposure' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_45 patient_47], :isolation, 'all', 'Unknown', nil, false)
  end

  test 'bulk edit case status from exposure to isolation with household' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_52], :exposure, 'all', 'Confirmed',
                                                             'Continue Monitoring in Isolation Workflow', true)
  end

  test 'bulk edit case status from isolation to exposure with household' do
    @@public_health_test_helper.bulk_edit_update_case_status('state1_epi', %w[patient_54], :isolation, 'all', 'Unknown', nil, true)
  end

  test 'bulk edit close records from exposure workflow' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_1 patient_2], :exposure, 'all', '', '', false)
  end

  test 'bulk edit close records from isolation workflow' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_45 patient_47], :isolation, 'all', 'Completed Monitoring', 'reasoning', false)
  end

  test 'bulk edit close records from exposure workflow with household' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_52], :exposure, 'all', 'Duplicate', '', true)
  end

  test 'bulk edit close records from isolation workflow with household' do
    @@public_health_test_helper.bulk_edit_close_records('state1_epi', %w[patient_54], :isolation, 'all', '', 'details', true)
  end
end
