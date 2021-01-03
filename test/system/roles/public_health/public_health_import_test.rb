# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthImport'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthImportExportTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'import epi-x to exposure and accept all' do
    @@public_health_test_helper.import_epi_x('state1_epi_enroller', :exposure, 'Epi-X-Format.xlsx', :valid, nil)
  end

  test 'import epi-x to isolation and accept all' do
    @@public_health_test_helper.import_epi_x('state1_epi_enroller', :isolation, 'Epi-X-Format.xlsx', :valid, nil)
  end

  test 'import epi-x to isolation and accept all individually' do
    @@public_health_test_helper.import_epi_x('state2_epi', :isolation, 'Epi-X-Format.xlsx', :valid, [])
  end

  test 'import epi-x to exposure and accept some' do
    @@public_health_test_helper.import_epi_x('locals2c3_epi', :exposure, 'Epi-X-Format.xlsx', :valid, [2, 5, 7, 8])
  end

  test 'import epi-x to isolation and reject all' do
    @@public_health_test_helper.import_epi_x('locals1c1_epi', :isolation, 'Epi-X-Format.xlsx', :valid, (0..10).to_a)
  end

  test 'import epi-x to exposure with duplicate patient and accept duplicates' do
    @@public_health_test_helper.import_epi_x('state5_epi', :exposure, 'Epi-X-Format.xlsx', :valid, nil, accept_duplicates: true)
  end

  test 'import epi-x to isolation with duplicate patient and reject duplicates' do
    @@public_health_test_helper.import_epi_x('state5_epi', :isolation, 'Epi-X-Format.xlsx', :valid, nil, accept_duplicates: false)
  end

  test 'import epi-x to isolation and validate file type' do
    @@public_health_test_helper.import_epi_x('locals2c4_epi', :isolation, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import epi-x to exposure and validate file format' do
    @@public_health_test_helper.import_epi_x('locals1c2_epi', :exposure, 'Invalid-Excel-File.xlsx', :invalid_format, nil)
  end

  test 'import epi-x to isolation and validate headers' do
    @@public_health_test_helper.import_epi_x('locals2c4_epi', :isolation, 'Epi-X-Format-Invalid-Headers.xlsx', :invalid_headers, nil)
  end

  test 'import epi-x to exposure and validate empty monitorees list' do
    @@public_health_test_helper.import_epi_x('locals2c3_epi', :exposure, 'Epi-X-Format-Invalid-Monitorees.xlsx', :invalid_monitorees, nil)
  end

  test 'import epi-x to exposure and validate fields' do
    @@public_health_test_helper.import_epi_x('locals1c2_epi', :exposure, 'Epi-X-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import epi-x to isolation and validate fields' do
    @@public_health_test_helper.import_epi_x('locals1c2_epi', :isolation, 'Epi-X-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import epi-x format and cancel' do
    @@public_health_test_helper.import_and_cancel('locals2c4_epi', :isolation, 'Epi-X-Format.xlsx', 'Epi-X')
  end

  test 'import sara alert format to exposure and accept all' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, nil)
  end

  test 'import sara alert format to isolation and accept all' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :isolation, 'Sara-Alert-Format-Isolation-Workflow.xlsx', :valid, nil)
  end

  test 'import sara alert format to exposure and accept all individually' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :exposure, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, [])
  end

  test 'import sara alert format to isolation and accept some' do
    @@public_health_test_helper.import_sara_alert_format('state2_epi', :isolation, 'Sara-Alert-Format-Isolation-Workflow.xlsx', :valid, [1, 4, 5, 9])
  end

  test 'import sara alert format to exposure and reject all' do
    @@public_health_test_helper.import_sara_alert_format('locals2c3_epi', :exposure, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, (0..10).to_a)
  end

  test 'import sara alert format to isolation with duplicate patient and accept duplicates' do
    # rubocop:disable Layout/LineLength
    @@public_health_test_helper.import_sara_alert_format('state5_epi', :isolation, 'Sara-Alert-Format-Isolation-Workflow.xlsx', :valid, nil, accept_duplicates: true)
    # rubocop:enable Layout/LineLength
  end

  test 'import sara alert format to exposure with duplicate patient and reject duplicates' do
    # rubocop:disable Layout/LineLength
    @@public_health_test_helper.import_sara_alert_format('state5_epi', :exposure, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, nil, accept_duplicates: false)
    # rubocop:enable Layout/LineLength
  end

  test 'import sara alert format to exposure with custom jurisdictions' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format-With-Jurisdictions-EW.xlsx', :valid, nil)
  end

  test 'import sara alert format to isolation with custom jurisdictions' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :isolation, 'Sara-Alert-Format-With-Jurisdictions-IW.xlsx', :valid, nil)
  end

  test 'import sara alert format to exposure and validate file type' do
    @@public_health_test_helper.import_sara_alert_format('locals1c2_epi', :exposure, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import sara alert format to isolation and validate file format' do
    @@public_health_test_helper.import_sara_alert_format('locals2c4_epi', :isolation, 'Invalid-Excel-File.xlsx', :invalid_format, nil)
  end

  test 'import sara alert format to exposure and validate headers' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format-Invalid-Headers.xlsx', :invalid_headers, nil)
  end

  test 'import sara alert format to isolation and validate empty monitorees list' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :isolation, 'Sara-Alert-Format-Invalid-Monitorees.xlsx',
                                                         :invalid_monitorees, nil)
  end

  test 'import sara alert format to exposure and validate fields' do
    @@public_health_test_helper.import_sara_alert_format('state1_epi', :exposure, 'Sara-Alert-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import sara alert format to isolation and validate fields' do
    @@public_health_test_helper.import_sara_alert_format('state2_epi', :isolation, 'Sara-Alert-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import sara alert format to exposure and validate jurisdiction path' do
    @@public_health_test_helper.import_sara_alert_format('locals2c4_epi', :exposure, 'Sara-Alert-Format-With-Jurisdictions-EW.xlsx', :invalid_fields, [])
  end

  test 'import sara alert format and cancel' do
    @@public_health_test_helper.import_and_cancel('locals2c4_epi', :exposure, 'Sara-Alert-Format-Exposure-Workflow.xlsx', 'Sara Alert Format')
  end

  # TODO: when workflow specific case status validation re-enabled: uncomment
  # test 'import sara alert format to exposure and validate workflow specific fields' do
  #   @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :exposure, 'Sara-Alert-Format-Isolation-Workflow.xlsx', :invalid_fields, [])
  # end

  # TODO: when workflow specific case status validation re-enabled: uncomment
  # test 'import sara alert format to isolation and validate workflow specific fields' do
  #   @@public_health_test_helper.import_sara_alert_format('state1_epi_enroller', :isolation, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :invalid_fields, [])
  # end

  # TODO: Re-enable when migrating away from GitHub LFS
  # test 'download sara alert format guidance from exposure workflow' do
  #   @@public_health_test_helper.download_sara_alert_format_guidance('state1_epi', :exposure)
  # end

  # TODO: Re-enable when migrating away from GitHub LFS
  # test 'download sara alert format guidance from isolation workflow' do
  #   @@public_health_test_helper.download_sara_alert_format_guidance('locals2c3_epi', :isolation)
  # end
end
