# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../../lib/system_test_utils'

class PublicHealthPatientPageReportsVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  STATUS_LABELS = {
    exposure_symptomatic: 'symptomatic',
    exposure_asymptomatic: 'asymptomatic',
    exposure_non_reporting: 'non-reporting',
    exposure_under_investigation: 'PUI',
    purged: 'purged',
    closed: 'not currently being monitored',
    isolation_requiring_review: 'requires review',
    isolation_symp_non_test_based: 'requires review (symptomatic non test based)',
    isolation_asymp_non_test_based: 'requires review (asymptomatic non test based)',
    isolation_test_based: 'requires review (test based)',
    isolation_non_reporting: 'non-reporting',
    isolation_reporting: 'reporting'
  }.freeze

  def verify_reports(patient_id, assessments = Assessment.where(patient_id: patient_id))
    patient = Patient.find(patient_id)
    reports = page.find('#reports')

    verify_workflow(patient[:isolation])
    verify_status(STATUS_LABELS[patient.status], reports)
    verify_notifications_button_text(patient[:pause_notifications], reports)

    # Wait for symptom headers to load on page
    sleep(0.5)
    table = reports.find('#assessments-table')
    headers = table.find('thead').all('th').map(&:text)

    # Verify that all symptom names are displayed
    symptom_names = Hash[assessments.joins({ reported_condition: :symptoms }).distinct.pluck(:name, :label)]
    symptom_labels = symptom_names.values
    assert_equal symptom_labels, symptom_labels & headers, "Missing symptom headers: #{symptom_labels - (symptom_labels & headers)}"

    # Determine column indexes of symptoms within table
    symptom_column_indexes = symptom_names.transform_values { |label| headers.index(label) }

    # Verify individual assessment data
    assessments.each do |assessment|
      row = table.find("#assessments-#{assessment[:id]}")
      assert_equal assessment[:symptomatic], row[:class].include?('table-danger'), "'Symptomatic color' for assessment #{assessment[:id]}"

      cells = row.all('td')
      assert_equal assessment[:id].to_s, cells[headers.index('ID')].text, "'ID' for assessment #{assessment[:id]}"
      if headers.include?('Needs Review')
        assert_equal assessment[:symptomatic] ? 'Yes' : 'No', cells[headers.index('Needs Review')].text, "'Needs Review' for assessment #{assessment[:id]}"
      end
      assert_equal assessment[:who_reported], cells[headers.index('Reporter')].text, "'Reporter' for assessment #{assessment[:id]}"

      # Verify symptom values
      assessment.reported_condition.symptoms.each do |symptom|
        cell = cells[symptom_column_indexes[symptom[:name]]]
        value = symptom.value
        value = value == true ? 'Yes' : 'No' if symptom[:type] == 'BoolSymptom' && !value.nil?
        assert_equal value || '', cell.text, "Symptom '#{symptom[:label]}' for assessment #{assessment[:id]}"
        assert_equal assessment.symptom_passes_threshold(symptom), cell.find('span')[:class].include?('concern'),
                     "'Symptomatic color' for symptom '#{symptom[:label]}' for assessment #{assessment[:id]}"
      end
    end
  end

  def verify_new_report(assessment)
    assert page.has_content?('Monitoree'), @@system_test_utils.get_err_msg('Reports', 'Reporter', 'Monitoree')
    verify_symptoms(assessment['symptoms'])
  end

  def verify_add_report(user_label, assessment)
    assert page.has_content?(user_label), @@system_test_utils.get_err_msg('Reports', 'Reporter', user_label)
    verify_symptoms(assessment['symptoms'])
  end

  def verify_edit_report(user_label, assessment)
    assert page.has_content?(user_label), @@system_test_utils.get_err_msg('Reports', 'Reporter', user_label)
    verify_symptoms(assessment['symptoms'])
  end

  def verify_symptoms(symptoms)
    symptoms.each do |symptom|
      case symptom['type']
      when 'BoolSymptom'
        assert page.has_content?(symptom['bool_value'] ? 'Yes' : 'No'), @@system_test_utils.get_err_msg('Report', 'boolean symptom', symptom['bool_value'])
      when 'FloatSymptom'
        assert page.has_content?(symptom['float_value']), @@system_test_utils.get_err_msg('Report', 'float symptom', symptom['float_value'])
      when 'IntegerSymptom'
        assert page.has_content?(symptom['int_value']), @@system_test_utils.get_err_msg('Report', 'int symptom', symptom['int_value'])
      end
    end
  end

  def verify_workflow(isolation, reports = page.find('#reports'))
    workflow = isolation ? 'Isolation' : 'Exposure'
    assert reports.has_content?(workflow), "Workflow (under 'Reports') should be #{workflow}"
  end

  def verify_status(status, reports = page.find('#reports'))
    assert reports.has_content?(status), "Status (under 'Reports') should be #{status}"
  end

  def verify_notifications_button_text(pause_notifications, reports = page.find('#reports'))
    notifications_button_text = "#{pause_notifications ? 'Resume' : 'Pause'} Notifications"
    assert reports.has_content?(notifications_button_text), "Notifications button (under 'Reports') should be #{notifications_button_text}"
  end
end
