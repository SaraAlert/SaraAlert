# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../system_test_utils'

class PublicHealthMonitoringExportVerifier < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)
    
  DOWNLOAD_TIMEOUT = 10
  DOWNLOAD_CHECK_INTERVAL = 0.1

  LINELIST_HEADERS = ['Monitoree', 'Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level', 'Monitoring Plan',
                      'Latest Report', 'Transferred At', 'Reason For Closure', 'Latest Public Health Action', 'Status', 'Closed At', 'Transferred From',
                      'Transferred To', 'Expected Purge Date'].freeze

  COMPREHENSIVE_HEADERS = ['First Name', 'Middle Name', 'Last Name', 'Date of Birth', 'Sex at Birth', 'White', 'Black or African American',
                           'American Indian or Alaska Native', 'Asian', 'Native Hawaiian or Other Pacific Islander', 'Ethnicity', 'Primary Language',
                           'Secondary Language', 'Interpretation Required?', 'Nationality', 'Identifier (STATE/LOCAL)', 'Identifier (CDC)',
                           'Identifier (NNDSS)', 'Address Line 1', 'Address City', 'Address State', 'Address Line 2', 'Address Zip', 'Address County',
                           'Foreign Address Line 1', 'Foreign Address City', 'Foreign Address Country', 'Foreign Address Line 2', 'Foreign Address Zip',
                           'Foreign Address Line 3', 'Foreign Address State', 'Monitored Address Line 1', 'Monitored Address City', 'Monitored Address State',
                           'Monitored Address Line 2', 'Monitored Address Zip', 'Monitored Address County', 'Foreign Monitored Address Line 1',
                           'Foreign Monitored Address City', 'Foreign Monitored Address State', 'Foreign Monitored Address Line 2',
                           'Foreign Monitored Address Zip', 'Foreign Monitored Address County', 'Preferred Contact Method', 'Primary Telephone',
                           'Primary Telephone Type', 'Secondary Telephone', 'Secondary Telephone Type', 'Preferred Contact Time', 'Email', 'Port of Origin',
                           'Date of Departure', 'Source of Report', 'Flight or Vessel Number', 'Flight or Vessel Carrier', 'Port of Entry Into USA',
                           'Date of Arrival', 'Travel Related Notes', 'Additional Planned Travel Type', 'Additional Planned Travel Destination',
                           'Additional Planned Travel Destination State', 'Additional Planned Travel Destination Country',
                           'Additional Planned Travel Port of Departure', 'Additional Planned Travel Start Date', 'Additional Planned Travel End Date',
                           'Additional Planned Travel Related Notes', 'Last Date of Exposure', 'Potential Exposure Location', 'Potential Exposure Country',
                           'Contact of Known Case?', 'Contact of Known Case ID', 'Travel from Affected Country or Area?',
                           'Was in Health Care Facility With Known Cases?', 'Health Care Facility with Known Cases Name', 'Laboratory Personnel?',
                           'Laboratory Personnel Facility Name', 'Health Care Personnel?', 'Health Care Personnel Facility Name',
                           'Crew on Passenger or Cargo Flight?', 'Member of a Common Exposure Cohort?', 'Common Exposure Cohort Name',
                           'Exposure Risk Assessment', 'Monitoring Plan', 'Exposure Notes', 'Status'].freeze

  MONITOREES_LIST_HEADERS = ['Patient ID'] + COMPREHENSIVE_HEADERS.freeze
  
  def verify_line_list_csv(jurisdiction_id, workflow)
    csv = get_csv("Sara-Alert-#{workflow == :isolation ? 'Isolation' : 'Exposure'}-Linelist-????-??-??T??_??_?????_??.csv")
    patients = Jurisdiction.find(jurisdiction_id).all_patients.where(isolation: workflow == :isolation)
    verify_csv_export(csv, :line_list, LINELIST_HEADERS, patients)
  end
  
  def verify_sara_alert_format(jurisdiction_id, workflow)
    xlsx = get_xlsx("Sara-Alert-Format-#{workflow == :isolation ? 'Isolation' : 'Exposure'}-????-??-??T??_??_?????_??.xlsx")
    patients = Jurisdiction.find(jurisdiction_id).all_patients.where(isolation: workflow == :isolation)
    verify_sara_alert_format_export(xlsx, patients)
  end

  def verify_excel_purge_eligible_monitorees(jurisdiction_id)
    xlsx = get_xlsx('Sara-Alert-Full-History-Purgeable-Monitorees-????-??-??T??_??_?????_??.xlsx')
    patients = Jurisdiction.find(jurisdiction_id).all_patients.purge_eligible
    verify_excel_export(xlsx, patients)
  end

  def verify_excel_all_monitorees(jurisdiction_id)
    xlsx = get_xlsx('Sara-Alert-Full-History-All-Monitorees-????-??-??T??_??_?????_??.xlsx')
    patients = Jurisdiction.find(jurisdiction_id).all_patients
    verify_excel_export(xlsx, patients)
  end

  def verify_excel_single_monitoree(patient_id)
    xlsx = get_xlsx("Sara-Alert-Full-History-Monitoree-#{patient_id}-????-??-??T??_??_?????_??.xlsx")
    patients = Patient.where(id: patient_id)
    verify_excel_export(xlsx, patients)
  end

  def verify_sara_alert_format_guidance
    xlsx = get_xlsx("sara_alert_comprehensive_monitoree.xlsx")
  end

  def verify_csv_export(csv, type, headers, patients)
    assert_equal(patients.size, csv.length(), "Number of patients")
    headers.each_with_index do |header, col|
      assert_equal(header, csv.headers[col], "For header: #{header}")
    end
    patients.each_with_index do |patient, row|
      details = type == :line_list ? patient.linelist : patient.comprehensive_details
      details.keys.each_with_index do |field, col|
        if field == :name
          assert_equal(details[field][:name], csv[row][col], "For field: #{field}")
        elsif details[field] == !!details[field]
          assert_equal(details[field] ? 'true' : 'false', csv[row][col], "For field: #{field}")
        else
          assert_equal(details[field], csv[row][col], "For field: #{field}")
        end
      end
    end
  end

  def verify_sara_alert_format_export(xlsx, patients)
    monitorees = xlsx.sheet('Monitorees')
    assert_equal(patients.size, monitorees.last_row - 1, "Number of patients")
    COMPREHENSIVE_HEADERS.each_with_index do |header, col|
      assert_equal(header, monitorees.cell(1, col + 1), "For header: #{header}")
    end
    patients.each_with_index do |patient, row|
      details = patient.comprehensive_details
      details.keys.each_with_index do |field, col|
        cell_value = monitorees.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value ? cell_value : '', "For field: #{field}")
      end
    end
  end

  def verify_excel_export(xlsx, patients)
    monitorees_list = xlsx.sheet('Monitorees List')
    assert_equal(patients.size, monitorees_list.last_row - 1, "Number of patients in Monitorees List")
    MONITOREES_LIST_HEADERS.each_with_index do |header, col|
      assert_equal(header, monitorees_list.cell(1, col + 1), "For header: #{header} in Monitorees List")
    end
    patients.each_with_index do |patient, row|
      details = { patient_id: patient.id }.merge(patient.comprehensive_details)
      details.keys.each_with_index do |field, col|
        cell_value = monitorees_list.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value ? cell_value : '', "For field: #{field} in Monitorees List")
      end
    end

    patient_ids = patients.pluck(:id)

    assessments = xlsx.sheet('Assessments')
    assessment_ids = Assessment.where(patient_id: patient_ids).pluck(:id)
    condition_ids = ReportedCondition.where(assessment_id: assessment_ids).pluck(:id)
    symptom_label_and_names = Symptom.where(condition_id: condition_ids).pluck(:label, :name).uniq
    symptom_labels = symptom_label_and_names.collect { |s| s[0] }
    symptom_names = symptom_label_and_names.collect { |s| s[1] }
    patient_info_headers = %w[patient_id symptomatic who_reported created_at updated_at]
    assessment_headers = patient_info_headers + symptom_names
    human_readable_headers = ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels
    human_readable_headers.each_with_index do |header, col|
      assert_equal(header, assessments.cell(1, col + 1), "For header: #{header} in Assessments")
    end
    assessment_summaries = []
    patients.each do |patient|
      patient.assessmenmts_summary_array(patient_info_headers, symptom_names).each do |assessment|
        assessment_summaries.append(assessment)
      end
    end
    assert_equal(assessment_summaries.size, assessments.last_row - 1, "Number of assessments in Assessments")
    assessment_summaries.each_with_index do |assessment_summary, row|
      assessment_summary.each_with_index do |value, col|
        cell_value = assessments.cell(row + 2, col + 1)
        if (value == !!value && value) || (col == 1 && value == 1)
          assert_equal('true', cell_value, "For field: #{assessment_headers[col]} in Assessments")
        elsif (value == !!value && !value) || (col == 1 && value != 1)
          assert_nil(cell_value, "For field: #{assessment_headers[col]} in Assessments")
        else
          assert_equal(value.to_s, cell_value ? cell_value : '', "For field: #{assessment_headers[col]} in Assessments")
        end
      end
    end

    lab_results = xlsx.sheet('Lab Results')
    labs = Laboratory.where(patient_id: patient_ids)
    assert_equal(labs.size, lab_results.last_row - 1, "Number of results in Lab Results")
    lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
    lab_headers.each_with_index do |header, col|
      assert_equal(header, lab_results.cell(1, col + 1), "For header: #{header} in Lab Results")
    end
    labs.each_with_index do |lab, row|
      details = lab.details
      details.keys.each_with_index do |field, col|
        cell_value = lab_results.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value ? cell_value : '', "For field: #{field} in Lab Results")
      end
    end

    edit_histories = xlsx.sheet('Edit Histories')
    histories = History.where(patient_id: patient_ids)
    assert_equal(histories.size, edit_histories.last_row - 1, "Number of histories in Edit Histories")
    history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
    history_headers.each_with_index do |header, col|
      assert_equal(header, edit_histories.cell(1, col + 1), "For header: #{header} in Edit Histories")
    end
    histories.each_with_index do |history, row|
      details = history.details
      details.keys.each_with_index do |field, col|
        cell_value = edit_histories.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value ? cell_value : '', "For field: #{field} in Edit Histories")
      end
    end
  end

  def get_csv(file_name_glob)
    CSV.parse(File.read(get_file_name(file_name_glob)), :headers => true)
  end

  def get_xlsx(file_name_glob)
    Roo::Spreadsheet.open(get_file_name(file_name_glob))
  end

  def get_file_name(file_name_glob)
    Timeout.timeout(DOWNLOAD_TIMEOUT) do
      sleep(DOWNLOAD_CHECK_INTERVAL) until Dir.glob(File.join(@@system_test_utils.get_download_path, file_name_glob)).any?
    end
    Dir.glob(File.join(@@system_test_utils.get_download_path, file_name_glob))[0]
  end
end
