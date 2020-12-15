# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringExportVerifier < ApplicationSystemTestCase
  include ImportExport
  @@system_test_utils = SystemTestUtils.new(nil)

  DOWNLOAD_TIMEOUT = 5
  DOWNLOAD_CHECK_INTERVAL = 0.1

  def verify_csv_linelist(user_label, workflow)
    user = @@system_test_utils.get_user(user_label)
    export_type = "csv_linelist_#{workflow}".to_sym
    download_export_files(user, export_type)
    csv = get_csv(build_export_filename({ export_type: export_type, format: :csv }, nil, 0, true))
    patients = user.jurisdiction.all_patients.where(isolation: workflow == :isolation).order(:id)
    verify_csv_linelist_export(csv, LINELIST_HEADERS, patients)
  end

  def verify_sara_alert_format(user_label, workflow)
    user = @@system_test_utils.get_user(user_label)
    export_type = "sara_alert_format_#{workflow}".to_sym
    download_export_files(user, export_type)
    xlsx = get_xlsx(build_export_filename({ export_type: export_type, format: :xlsx }, nil, 0, true))
    patients = user.jurisdiction.all_patients.where(isolation: workflow == :isolation).order(:id)
    verify_sara_alert_format_export(xlsx, patients)
  end

  def verify_full_history_patients(user_label, scope)
    user = @@system_test_utils.get_user(user_label)
    export_type = "full_history_patients_#{scope}".to_sym
    config = {
      export_type: export_type,
      format: :xlsx,
      filename_data_type: true,
      data: {
        patients: {
          name: 'Monitorees'
        },
        assessments: {
          name: 'Reports'
        },
        laboratories: {
          name: 'Lab-Results'
        },
        histories: {
          name: 'Histories'
        }
      }
    }
    download_export_files(user, export_type)
    xlsx_monitorees = get_xlsx(build_export_filename(config, :patients, 0, true))
    xlsx_assessments = get_xlsx(build_export_filename(config, :assessments, 0, true))
    xlsx_lab_results = get_xlsx(build_export_filename(config, :laboratories, 0, true))
    xlsx_histories = get_xlsx(build_export_filename(config, :histories, 0, true))
    patients = user.jurisdiction.all_patients.order(:id)
    patients = patients.purge_eligible if scope == :purgeable
    patients = patients.order(:id)
    verify_full_history_export(xlsx_monitorees, xlsx_assessments, xlsx_lab_results, xlsx_histories, patients)
  end

  def verify_full_history_patient(patient_id)
    xlsx_all = get_xlsx("Sara-Alert-Monitoree-Export-#{patient_id}-????-??-??T??_??_?????_??.xlsx")
    patients = Patient.where(id: patient_id)
    verify_full_history_export(xlsx_all, xlsx_all, xlsx_all, xlsx_all, patients)
  end

  def verify_custom(user_label, settings)
    user = @@system_test_utils.get_user(user_label)
    export_type = :custom
    config = {
      export_type: export_type,
      format: settings[:format],
      filename_data_type: settings[:format] == :csv
    }
    download_export_files(user, export_type)
    if settings[:format] == :csv
      export_files = {}
      settings[:elements]&.each_key do |data_type|
        export_files[data_type] = get_csv(build_export_filename(config, data_type, 0, true)) if settings.dig(:elements, data_type, :checked)&.present?
      end
      verify_custom_export_csv(user, settings, export_files)
    else
      verify_custom_export_xlsx(user, settings, get_xlsx(build_export_filename(config, nil, 0, true)))
    end
  end

  def verify_preset(user_label, settings)
    user = @@system_test_utils.get_user(user_label)
    preset = UserExportPreset.find_by(user: user, name: settings[:name])
    assert_not_nil preset
    config = JSON.parse(preset[:config])
    assert_equal settings[:format].to_s, config['format'], 'Export preset format mismatch'
    settings[:elements]&.each_key do |data_type|
      assert_not_nil config.dig('data', data_type.to_s, 'checked') if settings[:elements][data_type][:checked].present?
    end
  end

  def verify_sara_alert_format_guidance
    get_xlsx('Sara%20Alert%20Import%20Format.xlsx')
  end

  def verify_csv_linelist_export(csv, headers, patients)
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
        elsif %i[latest_report transferred_at].include?(field)
          if details[field].blank?
            assert_nil csv[row][col]&.to_datetime, "For field: #{field}"
          else
            sleep(4)
            assert_in_delta(details[field].to_datetime, csv[row][col].to_datetime, 1, "For field: #{field}")
          end
        else
          assert_equal(details[field].to_s, csv[row][col].to_s, "For field: #{field}")
        end
      end
    end
  end

  def verify_sara_alert_format_export(xlsx, patients)
    monitorees = xlsx.sheet('Monitorees')
    assert_equal(patients.size, monitorees.last_row - 1, 'Number of patients')
    SARA_ALERT_FORMAT_HEADERS.each_with_index do |header, col|
      assert_equal(header, monitorees.cell(1, col + 1), "For header: #{header}")
    end
    patients.each_with_index do |patient, row|
      details = patient.full_history_details
      details.keys.each_with_index do |field, col|
        cell_value = monitorees.cell(row + 2, col + 1)
        if field == :full_status
          assert_equal(patient.status&.to_s&.humanize&.downcase, cell_value, "For field: #{field} (row #{row + 1})")
        elsif %i[primary_telephone secondary_telephone].include?(field)
          assert_equal(format_phone_number(details[field]).to_s, cell_value || '', "For field: #{field} (row #{row + 1})")
        else
          assert_equal(details[field].to_s, cell_value || '', "For field: #{field} (row #{row + 1})")
        end
      end
    end
  end

  def verify_full_history_export(xlsx_monitorees, xlsx_assessments, xlsx_lab_results, xlsx_histories, patients)
    monitorees_list = xlsx_monitorees.sheet('Monitorees List')
    assert_equal(patients.size, monitorees_list.last_row - 1, 'Number of patients in Monitorees List')
    FULL_HISTORY_PATIENTS_HEADERS.each_with_index do |header, col|
      assert_equal(header, monitorees_list.cell(1, col + 1), "For header: #{header} in Monitorees List")
    end
    patients.each_with_index do |patient, row|
      details = { patient_id: patient.id }.merge(patient.full_history_details)
      details.keys.each_with_index do |field, col|
        cell_value = monitorees_list.cell(row + 2, col + 1)
        if field == :full_status
          assert_equal(patient.status&.to_s&.humanize&.downcase, cell_value, "For field: #{field} in Monitorees List (row #{row + 1})")
        elsif %i[primary_telephone secondary_telephone].include?(field)
          assert_equal(format_phone_number(details[field]).to_s, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        else
          assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        end
      end
    end

    patient_ids = patients.pluck(:id)

    assessments = xlsx_assessments.sheet('Reports')
    symptom_labels = Patient.where(id: patient_ids)
                            .joins(assessments: [{ reported_condition: :symptoms }])
                            .select('symptoms.label')
                            .distinct
                            .pluck('symptoms.label')
                            .sort
    assessment_headers = ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels.to_a.sort
    assessment_headers.each_with_index do |header, col|
      assert_equal(header, assessments.cell(1, col + 1), "For header: #{header} in Reports")
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
                  assert_equal(value.to_s, cell_value || '', "For field: #{assessment_headers[col]} in Reports")
                end
                assessment_row += 1
              end
            end

    lab_results = xlsx_lab_results.sheet('Lab Results')
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

    edit_histories = xlsx_histories.sheet('Edit Histories')
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

  def verify_custom_export_csv(user, settings, export_files)
    patients = patients_by_query(user, settings.dig(:patients, :query) || {})
    patient_ids = patients.pluck(:id)

    assert_equal(patients.size, export_files[:patients]&.length, 'Number of patients') if settings.dig(:elements, :patients, :checked)&.present?

    if settings.dig(:elements, :assessments, :checked)&.present?
      assessments = assessments_by_patient_ids(patient_ids)
      assert_equal(assessments.size, export_files[:assessments]&.length, 'Number of assessments')
    end

    if settings.dig(:elements, :laboratories, :checked)&.present?
      laboratories = laboratories_by_patient_ids(patient_ids)
      assert_equal(laboratories.size, export_files[:laboratories]&.length, 'Number of laboratories')
    end

    if settings.dig(:elements, :close_contacts, :checked)&.present?
      close_contacts = close_contacts_by_patient_ids(patient_ids)
      assert_equal(close_contacts.size, export_files[:close_contacts]&.length, 'Number of close contacts')
    end

    if settings.dig(:elements, :transfers, :checked)&.present?
      transfers = transfers_by_patient_ids(patient_ids)
      assert_equal(transfers.size, export_files[:transfers]&.length, 'Number of transfers')
    end

    return unless settings.dig(:elements, :histories, :checked)&.present?

    histories = histories_by_patient_ids(patient_ids)
    assert_equal(histories.size, export_files[:histories]&.length, 'Number of histories')
  end

  def verify_custom_export_xlsx(user, settings, export_file)
    patients = patients_by_query(user, settings.dig(:patients, :query) || {})
    patient_ids = patients.pluck(:id)

    if settings.dig(:elements, :patients, :checked)&.present?
      patients_sheet = export_file.sheet('Monitorees')
      assert_equal(patients.size, patients_sheet.last_row - 1, 'Number of patients in Monitorees List')
    end

    if settings.dig(:elements, :assessments, :checked)&.present?
      assessments = assessments_by_patient_ids(patient_ids)
      assessments_sheet = export_file.sheet('Reports')
      assert_equal(assessments.size, assessments_sheet.last_row - 1, 'Number of assessments in Reports List')
    end

    if settings.dig(:elements, :laboratories, :checked)&.present?
      laboratories = laboratories_by_patient_ids(patient_ids)
      laboratories_sheet = export_file.sheet('Lab Results')
      assert_equal(laboratories.size, laboratories_sheet.last_row - 1, 'Number of laboratories in Lab Reports List')
    end

    if settings.dig(:elements, :close_contacts, :checked)&.present?
      close_contacts = close_contacts_by_patient_ids(patient_ids)
      close_contacts_sheet = export_file.sheet('Close Contacts')
      assert_equal(close_contacts.size, close_contacts_sheet.last_row - 1, 'Number of close contacts in Close Contacts List')
    end

    if settings.dig(:elements, :transfers, :checked)&.present?
      transfers = transfers_by_patient_ids(patient_ids)
      transfers_sheet = export_file.sheet('Transfers')
      assert_equal(transfers.size, transfers_sheet.last_row - 1, 'Number of transfers in Transfers List')
    end

    return unless settings.dig(:elements, :histories, :checked)&.present?

    histories = histories_by_patient_ids(patient_ids)
    histories_sheet = export_file.sheet('History')
    assert_equal(histories.size, histories_sheet.last_row - 1, 'Number of histories in History List')
  end

  def download_export_files(user, export_type)
    sleep(1) # wait for export and download to complete
    Download.where(user_id: user.id, export_type: export_type.to_s).where('created_at > ?', 10.seconds.ago).find_each do |download|
      visit "/export/download/#{download.lookup}"
    end
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
    Dir.glob(File.join(@@system_test_utils.download_path, file_name_glob))&.first
  end
end
