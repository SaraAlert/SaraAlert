# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthExport'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthImportExportTest < ApplicationSystemTestCase
  @@public_health_test_helper = PublicHealthTestHelper.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)
  def setup
    # Reset ENV variables and reload export job file which has constants dependent on these ENV variables
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10_000'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '500'
    load 'app/jobs/export_job.rb'
  end

  def teardown
    # Reset ENV variables and reload export job file which has constants dependent on these ENV variables
    ENV['EXPORT_OUTER_BATCH_SIZE'] = nil
    ENV['EXPORT_INNER_BATCH_SIZE'] = nil
    load 'app/jobs/export_job.rb'

    # Remove any files downloaded for each test
    FileUtils.rm_rf(Rails.root.join('tmp/downloads'))
  end

  test 'export line list csv (exposure)' do
    @@public_health_test_helper.export_csv_linelist('locals2c3_epi', :exposure, :cancel)
    @@public_health_test_helper.export_csv_linelist('state1_epi', :exposure, :export)
  end

  test 'export line list csv (isolation)' do
    @@public_health_test_helper.export_csv_linelist('locals2c4_epi', :isolation, :cancel)
    @@public_health_test_helper.export_csv_linelist('state1_epi_enroller', :isolation, :export)
  end

  test 'export sara alert format (exposure)' do
    @@public_health_test_helper.export_sara_alert_format('locals1c1_epi', :exposure, :cancel)
    @@public_health_test_helper.export_sara_alert_format('state1_epi_enroller', :exposure, :export)
  end

  test 'export sara alert format (isolation)' do
    @@public_health_test_helper.export_sara_alert_format('locals2c3_epi', :isolation, :cancel)
    @@public_health_test_helper.export_sara_alert_format('state1_epi', :isolation, :export)
  end

  test 'export full history purge-eligible monitorees' do
    @@public_health_test_helper.export_full_history_patients('state1_epi_enroller', :isolation, :cancel, :purgeable)
    @@public_health_test_helper.export_full_history_patients('state1_epi', :exposure, :export, :purgeable)
  end

  test 'export full history all monitorees' do
    @@public_health_test_helper.export_full_history_patients('locals1c1_epi', :exposure, :cancel, :all)
    @@public_health_test_helper.export_full_history_patients('state1_epi', :isolation, :export, :all)
  end

  test 'export full history single monitoree' do
    @@public_health_test_helper.export_full_history_patient('locals2c4_epi', 'patient_10')
  end

  # ---- Test the same exports but with smaller batching so that the batching functionality can be tested ----

  test 'export line list csv (exposure) with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    @@public_health_test_helper.export_csv_linelist('locals2c3_epi', :exposure, :cancel)
    @@public_health_test_helper.export_csv_linelist('state1_epi', :exposure, :export)
  end

  test 'export line list csv (isolation) with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    @@public_health_test_helper.export_csv_linelist('locals2c4_epi', :isolation, :cancel)
    @@public_health_test_helper.export_csv_linelist('state1_epi_enroller', :isolation, :export)
  end

  test 'export sara alert format (exposure) with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    @@public_health_test_helper.export_sara_alert_format('locals1c1_epi', :exposure, :cancel)
    @@public_health_test_helper.export_sara_alert_format('state1_epi_enroller', :exposure, :export)
  end

  test 'export sara alert format (isolation) with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    @@public_health_test_helper.export_sara_alert_format('locals2c3_epi', :isolation, :cancel)
    @@public_health_test_helper.export_sara_alert_format('state1_epi', :isolation, :export)
  end

  test 'export full history purge-eligible monitorees with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    @@public_health_test_helper.export_full_history_patients('state1_epi_enroller', :isolation, :cancel, :purgeable)
    @@public_health_test_helper.export_full_history_patients('state1_epi', :exposure, :export, :purgeable)
  end

  test 'export full history all monitorees with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    @@public_health_test_helper.export_full_history_patients('locals1c1_epi', :exposure, :cancel, :all)
    @@public_health_test_helper.export_full_history_patients('state1_epi', :isolation, :export, :all)
  end

  test 'export full history single monitoree with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    @@public_health_test_helper.export_full_history_patient('locals2c4_epi', 'patient_10')
  end
end
