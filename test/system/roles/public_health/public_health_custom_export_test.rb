# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCasePublicHealthCustomExport'

require_relative 'public_health_test_helper'
require_relative '../../lib/system_test_utils'

class PublicHealthCustomExportTest < ApplicationSystemTestCase
  include ImportExport

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

  # Recursively grabs all the "leaf" field options in custom export
  def get_all_field_options(options)
    leaf_values = []
    options.each do |option|
      if option[:children].present?
        leaf_values.concat(get_all_field_options(option[:children]))
      else
        leaf_values << option[:value].to_sym
      end
    end
    leaf_values
  end

  # Gets all the patient field options for custom export.
  def all_custom_export_patient_fields
    # NOTE: Doesn't use PATIENT_FIELD_NAMES as that contains options not available to custom export
    options_tree = ImportExport::PATIENTS_EXPORT_OPTIONS
    get_all_field_options(options_tree[:nodes])
  end

  # Gets all the assessment field options for custom export.
  def all_custom_export_assessment_fields
    options_tree = ImportExport::ASSESSMENTS_EXPORT_OPTIONS
    get_all_field_options(options_tree[:nodes])
  end

  # TODO: Tests for custom query option
  # TODO: Tests for some options not being checked

  test 'export xlsx format with monitorees on current exposure symptomatic dashboard with all data types with all fields' do
    settings = {
      records: :current,
      workflow: :exposure,
      tab: :symptomatic,
      name: 'Excel export all',
      format: :xlsx,
      actions: %i[save export],
      confirm: :start,
      data: {
        patients: {
          selected: ['Monitoree Details'],
          checked: all_custom_export_patient_fields,
          query: {
            workflow: 'exposure',
            tab: 'symptomatic',
            jurisdiction: 2,
            scope: 'all',
            user: nil,
            search: '',
            tz_offset: 300
          }
        },
        assessments: {
          selected: ['Reports'],
          checked: all_custom_export_assessment_fields
        },
        laboratories: {
          selected: ['Lab Results']
        },
        close_contacts: {
          selected: ['Close Contacts']
        },
        transfers: {
          selected: ['Transfers']
        },
        histories: {
          selected: ['History']
        }
      }
    }
    @@public_health_test_helper.export_custom('state1_epi', settings)
  end

  test 'export xlsx format with monitorees on current isolation requires review dashboard with all data types with all fields' do
    settings = {
      records: :current,
      workflow: :isolation,
      tab: :requiring_review,
      name: 'Excel export all',
      format: :xlsx,
      actions: %i[save export],
      confirm: :start,
      data: {
        patients: {
          selected: ['Monitoree Details'],
          checked: all_custom_export_patient_fields,
          query: {
            workflow: 'isolation',
            tab: 'requiring_review',
            jurisdiction: 2,
            scope: 'all',
            user: nil,
            search: '',
            tz_offset: 300
          }
        },
        assessments: {
          selected: ['Reports'],
          checked: all_custom_export_assessment_fields
        },
        laboratories: {
          selected: ['Lab Results']
        },
        close_contacts: {
          selected: ['Close Contacts']
        },
        transfers: {
          selected: ['Transfers']
        },
        histories: {
          selected: ['History']
        }
      }
    }
    @@public_health_test_helper.export_custom('state1_epi', settings)
  end

  test 'export xlsx format with all monitorees with all data types with all fields' do
    settings = {
      records: :all,
      name: 'Excel export all',
      format: :xlsx,
      actions: %i[save export],
      confirm: :start,
      data: {
        patients: {
          selected: ['Monitoree Details'],
          checked: all_custom_export_patient_fields,
          query: {
            workflow: 'all',
            tab: 'all',
            jurisdiction: 1,
            scope: 'all',
            user: nil,
            search: '',
            tz_offset: 300
          }
        },
        assessments: {
          selected: ['Reports'],
          checked: all_custom_export_assessment_fields
        },
        laboratories: {
          selected: ['Lab Results']
        },
        close_contacts: {
          selected: ['Close Contacts']
        },
        transfers: {
          selected: ['Transfers']
        },
        histories: {
          selected: ['History']
        }
      }
    }
    @@public_health_test_helper.export_custom('state1_epi', settings)
  end

  # ---- Test the same exports but with smaller batching so that the batching functionality can be tested ----

  test 'export xlsx format with monitorees on current exposure symptomatic dashboard with all data types with all fields with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    settings = {
      records: :current,
      workflow: :exposure,
      tab: :symptomatic,
      name: 'Excel export all',
      format: :xlsx,
      actions: %i[save export],
      confirm: :start,
      data: {
        patients: {
          selected: ['Monitoree Details'],
          checked: all_custom_export_patient_fields,
          query: {
            workflow: 'exposure',
            tab: 'symptomatic',
            jurisdiction: 2,
            scope: 'all',
            user: nil,
            search: '',
            tz_offset: 300
          }
        },
        assessments: {
          selected: ['Reports'],
          checked: all_custom_export_assessment_fields
        },
        laboratories: {
          selected: ['Lab Results']
        },
        close_contacts: {
          selected: ['Close Contacts']
        },
        transfers: {
          selected: ['Transfers']
        },
        histories: {
          selected: ['History']
        }
      }
    }
    @@public_health_test_helper.export_custom('state1_epi', settings)
  end

  test 'export xlsx format with monitorees on current isolation requires review dashboard with all data types with all fields with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    settings = {
      records: :current,
      workflow: :isolation,
      tab: :requiring_review,
      name: 'Excel export all',
      format: :xlsx,
      actions: %i[save export],
      confirm: :start,
      data: {
        patients: {
          selected: ['Monitoree Details'],
          checked: all_custom_export_patient_fields,
          query: {
            workflow: 'isolation',
            tab: 'requiring_review',
            jurisdiction: 2,
            scope: 'all',
            user: nil,
            search: '',
            tz_offset: 300
          }
        },
        assessments: {
          selected: ['Reports'],
          checked: all_custom_export_assessment_fields
        },
        laboratories: {
          selected: ['Lab Results']
        },
        close_contacts: {
          selected: ['Close Contacts']
        },
        transfers: {
          selected: ['Transfers']
        },
        histories: {
          selected: ['History']
        }
      }
    }
    @@public_health_test_helper.export_custom('state1_epi', settings)
  end

  test 'export xlsx format with all monitorees with all data types with all fields with batching' do
    ENV['EXPORT_OUTER_BATCH_SIZE'] = '10'
    ENV['EXPORT_INNER_BATCH_SIZE'] = '2'
    load 'app/jobs/export_job.rb'

    settings = {
      records: :all,
      name: 'Excel export all',
      format: :xlsx,
      actions: %i[save export],
      confirm: :start,
      data: {
        patients: {
          selected: ['Monitoree Details'],
          checked: all_custom_export_patient_fields,
          query: {
            workflow: 'all',
            tab: 'all',
            jurisdiction: 1,
            scope: 'all',
            user: nil,
            search: '',
            tz_offset: 300
          }
        },
        assessments: {
          selected: ['Reports'],
          checked: all_custom_export_assessment_fields
        },
        laboratories: {
          selected: ['Lab Results']
        },
        close_contacts: {
          selected: ['Close Contacts']
        },
        transfers: {
          selected: ['Transfers']
        },
        histories: {
          selected: ['History']
        }
      }
    }
    @@public_health_test_helper.export_custom('state1_epi', settings)
  end
end
