# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthImport'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthImportExportTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  # Sara Alert Format

  test 'import sara alert format to exposure and accept all' do
    @@public_health_test_helper.import('state1_epi', :exposure, :saf, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, nil)
  end

  test 'import sara alert format to exposure and accept all individually' do
    @@public_health_test_helper.import('state1_epi_enroller', :exposure, :saf, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, [])
  end

  test 'import sara alert format to isolation and accept some' do
    @@public_health_test_helper.import('state2_epi', :isolation, :saf, 'Sara-Alert-Format-Isolation-Workflow.xlsx', :valid, [1, 4, 5, 9])
  end

  test 'import sara alert format to exposure and reject all' do
    @@public_health_test_helper.import('locals2c3_epi', :exposure, :saf, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, (0..10).to_a)
  end

  test 'import sara alert format to isolation with duplicate patient and accept duplicates' do
    @@public_health_test_helper.import('state5_epi', :isolation, :saf, 'Sara-Alert-Format-Isolation-Workflow.xlsx', :valid, nil, accept_duplicates: true)
  end

  test 'import sara alert format to exposure with duplicate patient and reject duplicates' do
    @@public_health_test_helper.import('state5_epi', :exposure, :saf, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :valid, nil, accept_duplicates: false)
  end

  test 'import sara alert format to exposure with custom jurisdictions' do
    @@public_health_test_helper.import('state1_epi', :exposure, :saf, 'Sara-Alert-Format-With-Jurisdictions-EW.xlsx', :valid, nil)
  end

  test 'import sara alert format to isolation with custom jurisdictions' do
    @@public_health_test_helper.import('state1_epi_enroller', :isolation, :saf, 'Sara-Alert-Format-With-Jurisdictions-IW.xlsx', :valid, nil)
  end

  test 'import sara alert format to exposure and validate file type' do
    @@public_health_test_helper.import('locals1c2_epi', :exposure, :saf, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import sara alert format to isolation and validate file format' do
    @@public_health_test_helper.import('locals2c4_epi', :isolation, :saf, 'Invalid-Excel-File.xlsx', :invalid_format, nil)
  end

  test 'import sara alert format to exposure and validate headers' do
    @@public_health_test_helper.import('state1_epi', :exposure, :saf, 'Sara-Alert-Format-Invalid-Headers.xlsx', :invalid_headers, nil)
  end

  test 'import sara alert format to isolation and validate empty monitorees list' do
    @@public_health_test_helper.import('state1_epi_enroller', :isolation, :saf, 'Sara-Alert-Format-Invalid-Monitorees.xlsx', :invalid_monitorees, nil)
  end

  test 'import sara alert format to exposure and validate fields' do
    @@public_health_test_helper.import('state1_epi', :exposure, :saf, 'Sara-Alert-Format-Invalid-Fields.xlsx', :invalid_fields, nil)
  end

  test 'import sara alert format to exposure and validate jurisdiction path' do
    @@public_health_test_helper.import('locals2c4_epi', :exposure, :saf, 'Sara-Alert-Format-With-Jurisdictions-EW.xlsx', :invalid_fields, [])
  end

  # Epi-X Format

  test 'import epi-x to exposure and accept all' do
    @@public_health_test_helper.import('state1_epi_enroller', :exposure, :epix, 'Epi-X-Format.csv', :valid, nil)
  end

  test 'import epi-x to isolation and accept all' do
    @@public_health_test_helper.import('state1_epi_enroller', :isolation, :epix, 'Epi-X-Format.csv', :valid, nil)
  end

  test 'import epi-x to isolation and accept all individually' do
    @@public_health_test_helper.import('state2_epi', :isolation, :epix, 'Epi-X-Format.csv', :valid, [])
  end

  test 'import epi-x to exposure and accept some' do
    @@public_health_test_helper.import('locals2c3_epi', :exposure, :epix, 'Epi-X-Format.csv', :valid, [2, 5, 7, 8])
  end

  test 'import epi-x to isolation and reject all' do
    @@public_health_test_helper.import('locals1c1_epi', :isolation, :epix, 'Epi-X-Format.csv', :valid, (0..10).to_a)
  end

  test 'import epi-x to exposure with duplicate patient and accept duplicates' do
    @@public_health_test_helper.import('state5_epi', :exposure, :epix, 'Epi-X-Format.csv', :valid, nil, accept_duplicates: true)
  end

  test 'import epi-x to isolation with duplicate patient and reject duplicates' do
    @@public_health_test_helper.import('state5_epi', :isolation, :epix, 'Epi-X-Format.csv', :valid, nil, accept_duplicates: false)
  end

  test 'import epi-x to isolation and validate file type' do
    @@public_health_test_helper.import('locals2c4_epi', :isolation, :epix, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import epi-x to exposure and validate file format' do
    @@public_health_test_helper.import('locals1c2_epi', :exposure, :epix, 'Invalid-Csv-File.csv', :invalid_format, nil)
  end

  test 'import epi-x to isolation and validate headers' do
    @@public_health_test_helper.import('locals2c4_epi', :isolation, :epix, 'Epi-X-Format-Invalid-Headers.csv', :invalid_headers, nil)
  end

  test 'import epi-x to exposure and validate empty monitorees list' do
    @@public_health_test_helper.import('locals2c3_epi', :exposure, :epix, 'Epi-X-Format-Invalid-Monitorees.csv', :invalid_monitorees, nil)
  end

  test 'import epi-x to isolation and validate fields' do
    @@public_health_test_helper.import('locals1c2_epi', :isolation, :epix, 'Epi-X-Format-Invalid-Fields.csv', :invalid_fields, nil)
  end

  # SDX Format

  test 'import sdx to exposure and accept all' do
    @@public_health_test_helper.import('state1_epi', :exposure, :sdx, 'SDX-Format.csv', :valid, nil)
  end

  test 'import sdx to isolation and accept some' do
    @@public_health_test_helper.import('state2_epi', :isolation, :sdx, 'SDX-Format.csv', :valid, [1, 4, 5])
  end

  test 'import sdx to exposure and validate file type' do
    @@public_health_test_helper.import('locals2c4_epi', :exposure, :sdx, 'Invalid-Text-File.txt', :invalid_file, nil)
  end

  test 'import sdx to isolation and validate file format' do
    @@public_health_test_helper.import('locals2c3_epi', :isolation, :sdx, 'Invalid-Csv-File.csv', :invalid_format, nil)
  end

  test 'import sdx to isolation and validate headers' do
    @@public_health_test_helper.import('locals2c4_epi', :isolation, :sdx, 'SDX-Format-Invalid-Headers.csv', :invalid_headers, nil)
  end

  test 'import sdx to exposure and validate empty monitorees list' do
    @@public_health_test_helper.import('locals2c3_epi', :exposure, :sdx, 'SDX-Format-Invalid-Monitorees.csv', :invalid_monitorees, nil)
  end

  test 'import sdx to exposure and validate fields' do
    @@public_health_test_helper.import('locals1c2_epi', :exposure, :sdx, 'SDX-Format-Invalid-Fields.csv', :invalid_fields, nil)
  end

  # Other

  test 'import and cancel' do
    @@public_health_test_helper.import_and_cancel('locals2c4_epi', :exposure, 'Sara-Alert-Format-Exposure-Workflow.xlsx', 'Sara Alert Format')
  end

  # TODO: when workflow specific case status validation re-enabled: uncomment
  # test 'import sara alert format to exposure and validate workflow specific fields' do
  #   @@public_health_test_helper.import('state1_epi_enroller', :exposure, :saf, 'Sara-Alert-Format-Isolation-Workflow.xlsx', :invalid_fields, [])
  # end

  # TODO: when workflow specific case status validation re-enabled: uncomment
  # test 'import sara alert format to isolation and validate workflow specific fields' do
  #   @@public_health_test_helper.import('state1_epi_enroller', :isolation, :saf, 'Sara-Alert-Format-Exposure-Workflow.xlsx', :invalid_fields, [])
  # end

  # TODO: Re-enable when migrating away from GitHub LFS
  # test 'download sara alert format guidance from exposure workflow' do
  #   @@public_health_test_helper.download_saf_guidance('state1_epi', :exposure)
  # end

  # TODO: Re-enable when migrating away from GitHub LFS
  # test 'download sara alert format guidance from isolation workflow' do
  #   @@public_health_test_helper.download_saf_guidance('locals2c3_epi', :isolation)
  # end
end
