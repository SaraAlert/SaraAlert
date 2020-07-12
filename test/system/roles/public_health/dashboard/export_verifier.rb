# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringExportVerifier < ApplicationSystemTestCase
  include ImportExportHelper
  @@system_test_utils = SystemTestUtils.new(nil)

  DOWNLOAD_TIMEOUT = 10
  DOWNLOAD_CHECK_INTERVAL = 0.1

  def verify_line_list_csv(user_label, workflow)
    current_user = @@system_test_utils.get_user(user_label)
    download_file(current_user, "csv_#{workflow}")
    csv = get_csv("Sara-Alert-Linelist-#{workflow == :isolation ? 'Isolation' : 'Exposure'}-????-??-??T??_??_?????_??.csv")
    patients = current_user.jurisdiction.all_patients.where(isolation: workflow == :isolation).order(:id)
    verify_line_list_export(csv, LINELIST_HEADERS, patients)
  end

  def verify_sara_alert_format(user_label, workflow)
    current_user = @@system_test_utils.get_user(user_label)
    download_file(current_user, "sara_format_#{workflow}")
    xlsx = get_xlsx("Sara-Alert-Format-#{workflow == :isolation ? 'Isolation' : 'Exposure'}-????-??-??T??_??_?????_??.xlsx")
    patients = current_user.jurisdiction.all_patients.where(isolation: workflow == :isolation).order(:id)
    verify_sara_alert_format_export(xlsx, patients)
  end

  def verify_excel_purge_eligible_monitorees(user_label)
    current_user = @@system_test_utils.get_user(user_label)
    download_file(current_user, 'full_history_purgeable')
    xlsx = get_xlsx('Sara-Alert-Purge-Eligible-Export-????-??-??T??_??_?????_??.xlsx')
    patients = current_user.jurisdiction.all_patients.purge_eligible.order(:id)
    verify_excel_export(xlsx, patients)
  end

  def verify_excel_all_monitorees(user_label)
    current_user = @@system_test_utils.get_user(user_label)
    download_file(current_user, 'full_history_all')
    xlsx = get_xlsx('Sara-Alert-Full-Export-????-??-??T??_??_?????_??.xlsx')
    patients = current_user.jurisdiction.all_patients.order(:id)
    verify_excel_export(xlsx, patients)
  end

  def verify_excel_single_monitoree(patient_id)
    xlsx = get_xlsx("Sara-Alert-Monitoree-Export-#{patient_id}-????-??-??T??_??_?????_??.xlsx")
    patients = Patient.where(id: patient_id)
    verify_excel_export(xlsx, patients)
  end

  def verify_sara_alert_format_guidance
    get_xlsx('Sara%20Alert%20Import%20Format.xlsx')
  end

  def verify_line_list_export(csv, headers, patients)
    assert_equal(patients.size, csv.length, 'Number of patients')
    headers.each_with_index do |header, col|
      assert_equal(header, csv.headers[col], "For header: #{header}")
    end
    patients.each_with_index do |patient, row|
      assert_equal(patient[:id].to_s, csv[row][0], 'For field: id')
      details = patient.linelist
      details.keys.each_with_index do |field, col|
        if [true, false].include?(details[field])
          assert_equal(details[field] ? 'true' : 'false', csv[row][col], "For field: #{field}")
        else
          assert_equal(details[field].to_s, csv[row][col].to_s, "For field: #{field}")
        end
      end
    end
  end

  def verify_sara_alert_format_export(xlsx, patients)
    monitorees = xlsx.sheet('Monitorees')
    assert_equal(patients.size, monitorees.last_row - 1, 'Number of patients')
    COMPREHENSIVE_HEADERS.each_with_index do |header, col|
      assert_equal(header, monitorees.cell(1, col + 1), "For header: #{header}")
    end
    patients.each_with_index do |patient, row|
      details = patient.comprehensive_details
      details.keys.each_with_index do |field, col|
        cell_value = monitorees.cell(row + 2, col + 1)
        if field == :status
          assert_equal(patient.status&.to_s&.humanize&.downcase, cell_value, "For field: #{field}")
        else
          assert_equal(details[field].to_s, cell_value || '', "For field: #{field}")
        end
      end
    end
  end

  def verify_excel_export(xlsx, patients)
    monitorees_list = xlsx.sheet('Monitorees List')
    assert_equal(patients.size, monitorees_list.last_row - 1, 'Number of patients in Monitorees List')
    MONITOREES_LIST_HEADERS.each_with_index do |header, col|
      assert_equal(header, monitorees_list.cell(1, col + 1), "For header: #{header} in Monitorees List")
    end
    patients.each_with_index do |patient, row|
      details = { patient_id: patient.id }.merge(patient.comprehensive_details)
      details.keys.each_with_index do |field, col|
        cell_value = monitorees_list.cell(row + 2, col + 1)
        if field == :status
          assert_equal(patient.status&.to_s&.humanize&.downcase, cell_value, "For field: #{field} in Monitorees List")
        else
          assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Monitorees List")
        end
      end
    end

    patient_ids = patients.pluck(:id)

    assessments = xlsx.sheet('Assessments')
    symptom_labels = Patient.where(id: patient_ids)
                            .joins(assessments: [{ reported_condition: :symptoms }])
                            .select('symptoms.label')
                            .distinct
                            .pluck('symptoms.label')
                            .sort
    assessment_headers = ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels.to_a.sort
    assessment_headers.each_with_index do |header, col|
      assert_equal(header, assessments.cell(1, col + 1), "For header: #{header} in Assessments")
    end
    assessment_row = 0
    patients.joins(assessments: [{ reported_condition: :symptoms }])
            .includes(assessments: [{ reported_condition: :symptoms }])
            .find_each do |patient|
              patient.assessments.find_each do |assessment|
                assessment_summary_arr = %i[patient_id symptomatic who_reported created_at updated_at].map { |field| assessment[field] }
                symptoms_hash = Hash[assessment.reported_condition.symptoms.map { |symptom| [symptom[:label], symptom.value] }]
                symptoms_arr = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s || '' }
                assessment_summary_arr.concat(symptoms_arr).each_with_index do |value, col|
                  cell_value = assessments.cell(assessment_row + 2, col + 1)
                  assert_equal(value.to_s, cell_value || '', "For field: #{assessment_headers[col]} in Assessments")
                end
                assessment_row += 1
              end
            end

    lab_results = xlsx.sheet('Lab Results')
    labs = Laboratory.where(patient_id: patient_ids)
    assert_equal(labs.size, lab_results.last_row - 1, 'Number of results in Lab Results')
    lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
    lab_headers.each_with_index do |header, col|
      assert_equal(header, lab_results.cell(1, col + 1), "For header: #{header} in Lab Results")
    end
    labs.each_with_index do |lab, row|
      details = lab.details
      details.keys.each_with_index do |field, col|
        cell_value = lab_results.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Lab Results")
      end
    end

    edit_histories = xlsx.sheet('Edit Histories')
    histories = History.where(patient_id: patient_ids)
    assert_equal(histories.size, edit_histories.last_row - 1, 'Number of histories in Edit Histories')
    history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
    history_headers.each_with_index do |header, col|
      assert_equal(header, edit_histories.cell(1, col + 1), "For header: #{header} in Edit Histories")
    end
    histories.each_with_index do |history, row|
      details = history.details
      details.keys.each_with_index do |field, col|
        cell_value = edit_histories.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Edit Histories")
      end
    end
  end

  def download_file(current_user, export_type)
    @@system_test_utils.wait_for_export_delay
    download = Download.where(user_id: current_user.id, export_type: export_type).where('created_at > ?', 5.seconds.ago).first
    visit "/export/download/#{download.lookup}"
    download.filename
  end

  def get_csv(file_name_glob)
    CSV.parse(File.read(get_file_name(file_name_glob)), headers: true)
  end

  def get_xlsx(file_name_glob)
    Roo::Spreadsheet.open(get_file_name(file_name_glob))
  end

  def get_file_name(file_name_glob)
    Timeout.timeout(DOWNLOAD_TIMEOUT) do
      sleep(DOWNLOAD_CHECK_INTERVAL) until Dir.glob(File.join(@@system_test_utils.download_path, file_name_glob)).any?
    end
    Dir.glob(File.join(@@system_test_utils.download_path, file_name_glob))[0]
  end
end
