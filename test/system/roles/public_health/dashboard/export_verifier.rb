# frozen_string_literal: true

require 'application_system_test_case'
require 'roo'

require_relative '../../../lib/system_test_utils'

class PublicHealthMonitoringExportVerifier < ApplicationSystemTestCase
  include ImportExport
  include Languages
  @@system_test_utils = SystemTestUtils.new(nil)

  DOWNLOAD_TIMEOUT = 5
  DOWNLOAD_CHECK_INTERVAL = 0.1

  def verify_csv_linelist(user_label, workflow)
    user = @@system_test_utils.get_user(user_label)
    export_type = "csv_linelist_#{workflow}".to_sym
    download_export_files(user, export_type)
    patients = user.jurisdiction.all_patients_excluding_purged.where(isolation: workflow == :isolation).reorder('')

    csv = get_csv("Sara-Alert-Linelist-#{workflow.to_s.humanize}-????-??-??T??-??-?????-??.csv")
    verify_csv_linelist_export(csv, patients.order(:id))
  end

  def verify_sara_alert_format(user_label, workflow)
    user = @@system_test_utils.get_user(user_label)
    export_type = "sara_alert_format_#{workflow}".to_sym
    download_export_files(user, export_type)
    patients = user.jurisdiction.all_patients_excluding_purged.where(isolation: workflow == :isolation).reorder('')
    xlsx = get_xlsx("Sara-Alert-Format-#{workflow.to_s.humanize}-????-??-??T??-??-?????-??.xlsx")
    verify_sara_alert_format_export(xlsx, patients.order(:id))
  end

  def verify_full_history_patients(user_label, scope)
    user = @@system_test_utils.get_user(user_label)
    export_type = "full_history_patients_#{scope}".to_sym
    download_export_files(user, export_type)
    patients = user.jurisdiction.all_patients_excluding_purged.order(:id)
    if scope == :purgeable
      patients = patients.purge_eligible
      xlsx_full_history = get_xlsx('Sara-Alert-Purge-Eligible-Export-????-??-??T??-??-?????-??.xlsx')
    else
      xlsx_full_history = get_xlsx('Sara-Alert-Full-Export-????-??-??T??-??-?????-??.xlsx')
    end
    patients_group = patients.order(:id)

    verify_full_history_export(xlsx_full_history, patients_group)
  end

  def verify_full_history_patient(patient_id)
    xlsx_all = get_xlsx("Sara-Alert-Monitoree-Export-#{patient_id}-????-??-??T??_??_?????_??.xlsx")
    patients = Patient.where(id: patient_id)
    verify_full_history_export(xlsx_all, patients)
  end

  def verify_custom(user_label, settings)
    user = @@system_test_utils.get_user(user_label)
    export_type = :custom
    download_export_files(user, export_type)

    patients = patients_by_query(user, settings.dig(:data, :patients, :query) || {})
    patients_group = patients.reorder('')

    if settings[:format] == :csv
      export_files = {}
      settings[:data]&.each_key do |data_type|
        export_files[data_type] = get_csv('Sara-Alert-Custom-Export-????-??-??T??-??-?????-??.csv') if settings.dig(:data, data_type, :checked)&.present?
      end
      verify_custom_export_csv(patients_group, settings, export_files)
    else
      xlsx = get_xlsx('Sara-Alert-Custom-Export-????-??-??T??-??-?????-??.xlsx')
      verify_custom_export_xlsx(patients_group.order(:id), settings, xlsx)
    end
  end

  def verify_preset(user_label, settings)
    user = @@system_test_utils.get_user(user_label)
    preset = UserExportPreset.find_by(user: user, name: settings[:name])
    assert_not_nil preset
    config = JSON.parse(preset[:config])
    assert_equal settings[:format].to_s, config['format'], 'Export preset format mismatch'
    settings[:data]&.each_key do |data_type|
      assert_not_nil config.dig('data', data_type.to_s, 'checked') if settings[:data][data_type][:checked].present?
    end
  end

  def verify_sara_alert_format_guidance
    get_xlsx('Sara%20Alert%20Import%20Format.xlsx')
  end

  def verify_csv_linelist_export(csv, patients)
    assert_equal(patients.size, csv.length, 'Number of patients')
    LINELIST_HEADERS.each_with_index do |header, col|
      assert_equal(header, csv.headers[col], "For header: #{header}")
    end
    patients.each_with_index do |patient, row|
      assert_equal(patient[:id].to_s, csv[row][0], 'For field: id')
      details = patient.linelist_for_export
      LINELIST_FIELDS.each_with_index do |field, col|
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
      details = patient.full_history_details_for_export
      SARA_ALERT_FORMAT_FIELDS.each_with_index do |field, col|
        cell_value = monitorees.cell(row + 2, col + 1)
        if field == :full_status
          assert_equal(patient.status&.to_s&.humanize&.downcase, cell_value, "For field: #{field} (row #{row + 1})")
        elsif %i[primary_telephone secondary_telephone].include?(field)
          assert_equal(format_phone_number(details[field]).to_s, cell_value || '', "For field: #{field} (row #{row + 1})")
        elsif %i[primary_language secondary_language].include?(field)
          assert_equal(Languages.translate_code_to_display(details[field]).to_s, cell_value || '', "For field: #{field} (row #{row + 1})")
        else
          assert_equal(details[field].to_s, cell_value || '', "For field: #{field} (row #{row + 1})")
        end
      end
    end
  end

  def verify_full_history_export(xlsx_full_history, patients)
    # Convert patients back into an AR collection for compatability
    patients = Patient.where(id: patients.pluck(:id))
    monitorees_list = xlsx_full_history.sheet('Monitorees List')
    assert_equal(patients.size, monitorees_list.last_row - 1, 'Number of patients in Monitorees List')
    FULL_HISTORY_PATIENTS_HEADERS.each_with_index do |header, col|
      assert_equal(header, monitorees_list.cell(1, col + 1), "For header: #{header} in Monitorees List")
    end
    patients.each_with_index do |patient, row|
      details = { patient_id: patient.id }.merge(patient.full_history_details_for_export)
      details.keys.each_with_index do |field, col|
        cell_value = monitorees_list.cell(row + 2, col + 1)
        if field == :full_status
          assert_equal(patient.status&.to_s&.humanize&.downcase, cell_value, "For field: #{field} in Monitorees List (row #{row + 1})")
        elsif %i[primary_telephone secondary_telephone].include?(field)
          assert_equal(format_phone_number(details[field]).to_s, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        elsif %i[primary_language secondary_language].include?(field)
          assert_equal(Languages.translate_code_to_display(details[field]).to_s, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        else
          assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        end
      end
    end

    patient_ids = patients.pluck(:id)

    assessments = xlsx_full_history.sheet('Reports')
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
                symptoms_hash = assessment.reported_condition.symptoms.map { |symptom| [symptom[:label], symptom.value] }.to_h
                symptoms_arr = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s || '' }
                assessment_summary_arr.concat(symptoms_arr).each_with_index do |value, col|
                  cell_value = assessments.cell(assessment_row + 2, col + 1)
                  assert_equal(value.to_s, cell_value || '', "For field: #{assessment_headers[col]} in Reports")
                end
                assessment_row += 1
              end
            end

    lab_results = xlsx_full_history.sheet('Lab Results')
    labs = Laboratory.where(patient_id: patient_ids)
    assert_equal(labs.size, lab_results.last_row - 1, 'Number of results in Lab Results')
    lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result', 'Created At', 'Updated At']
    lab_headers.each_with_index do |header, col|
      assert_equal(header, lab_results.cell(1, col + 1), "For header: #{header} in Lab Results")
    end
    labs.each_with_index do |lab, row|
      details = lab.attributes.except('id')
      details.keys.each_with_index do |field, col|
        cell_value = lab_results.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Lab Results")
      end
    end

    exported_vaccines = xlsx_full_history.sheet('Vaccinations')
    vaccines = Vaccine.where(patient_id: patient_ids).order(:patient_id)
    assert_equal(vaccines.size, exported_vaccines.last_row - 1, 'Number of results in Vaccinations')
    vaccine_headers = ['Patient ID', 'Vaccine Group', 'Product Name', 'Administration Date', 'Dose Number', 'Notes', 'Created At', 'Updated At']
    vaccine_headers.each_with_index do |header, col|
      assert_equal(header, exported_vaccines.cell(1, col + 1), "For header: #{header} in Vaccinations")
    end
    vaccines.each_with_index do |vaccine, row|
      details = vaccine.attributes.except('id')
      details.keys.each_with_index do |field, col|
        cell_value = exported_vaccines.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Vaccinations")
      end
    end

    edit_histories = xlsx_full_history.sheet('Edit Histories')
    histories = History.where(patient_id: patient_ids)
    assert_equal(histories.size, edit_histories.last_row - 1, 'Number of histories in Edit Histories')
    history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
    history_headers.each_with_index do |header, col|
      assert_equal(header, edit_histories.cell(1, col + 1), "For header: #{header} in Edit Histories")
    end
    histories.each_with_index do |history, row|
      details = history.attributes.except('id')
      details.keys.each_with_index do |field, col|
        cell_value = edit_histories.cell(row + 2, col + 1)
        assert_equal(details[field].to_s, cell_value || '', "For field: #{field} in Edit Histories")
      end
    end
  end

  def verify_custom_export_xlsx(patients, settings, export_file)
    # Duplicate because the data will be updated each call of this method (which matters with batching)
    data = settings[:data].deep_dup

    patient_ids = patients.pluck(:id)
    validate_custom_export_monitoree_details(patients, data, settings, export_file) if settings.dig(:data, :patients, :checked)&.present?

    validate_custom_export_assessmemts(patients, data, settings, export_file) if settings.dig(:data, :assessments, :checked)&.present?

    validate_custom_export_vaccines(patients, data, settings, export_file) if settings.dig(:data, :vaccines, :checked)&.present?

    if settings.dig(:data, :laboratories, :checked)&.present?
      laboratories = laboratories_by_patient_ids(patient_ids)
      laboratories_sheet = export_file.sheet('Lab Results')
      assert_equal(laboratories.size, laboratories_sheet.last_row - 1, 'Number of laboratories in Lab Reports List')

      # TODO: Validate lab headers
      # TODO: Validate lab cells
    end

    if settings.dig(:data, :close_contacts, :checked)&.present?
      close_contacts = close_contacts_by_patient_ids(patient_ids)
      close_contacts_sheet = export_file.sheet('Close Contacts')
      assert_equal(close_contacts.size, close_contacts_sheet.last_row - 1, 'Number of close contacts in Close Contacts List')

      # TODO: Validate close contact headers
      # TODO: Validate close contact cells
    end

    if settings.dig(:data, :transfers, :checked)&.present?
      transfers = transfers_by_patient_ids(patient_ids)
      transfers_sheet = export_file.sheet('Transfers')
      assert_equal(transfers.size, transfers_sheet.last_row - 1, 'Number of transfers in Transfers List')

      # TODO: Validate transfers headers
      # TODO: Validate transfers cells
    end

    return unless settings.dig(:data, :histories, :checked)&.present?

    histories = histories_by_patient_ids(patient_ids)
    histories_sheet = export_file.sheet('History')
    assert_equal(histories.size, histories_sheet.last_row - 1, 'Number of histories in History List')

    # TODO: Validate history headers
    # TODO: Validate history cells
  end

  def validate_custom_export_monitoree_details(patients, data, _settings, export_file)
    patients_sheet = export_file.sheet('Monitorees')
    assert_equal(patients.size, patients_sheet.last_row - 1, 'Number of patients in Monitorees List')

    checked = data.dig(:patients, :checked)

    # Replace "race" option with actual race field names
    race_index = checked.index(:race)
    checked.delete(:race)
    checked.insert(race_index, *PATIENT_FIELD_TYPES[:races])

    # Validate headers
    checked.each_with_index do |header, col|
      assert_equal(ImportExport::PATIENT_FIELD_NAMES[header], patients_sheet.cell(1, col + 1), "For header: #{header} in Monitorees List")
    end

    # Validate cell values
    patients.each_with_index do |patient, row|
      patient_details = { id: patient.id }.merge(patient.custom_export_details_for_export)
      checked.each_with_index do |field, col|
        cell_value = patients_sheet.cell(row + 2, col + 1)

        if field == :full_status
          assert_equal(patient.status&.to_s&.humanize&.downcase, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        elsif field == :status
          assert_equal(patient.status&.to_s&.humanize&.downcase&.sub('exposure ', '')&.sub('isolation ', ''), cell_value,
                       "For field: #{field} in Monitorees List (row #{row + 1})")
        elsif %i[primary_telephone secondary_telephone].include?(field)
          assert_equal(format_phone_number(patient_details[field]).to_s, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        elsif %i[primary_language secondary_language].include?(field)
          assert_equal(Languages.translate_code_to_display(patient_details[field]).to_s, cell_value || '',
                       "For field: #{field} in Monitorees List (row #{row + 1})")
        elsif field == :creator
          responder_email = User.find(patient.creator_id).email
          assert_equal(responder_email, cell_value, "For field: #{field} in Monitorees List (row #{row + 1})")
        else
          assert_equal(patient_details[field].to_s, cell_value || '', "For field: #{field} in Monitorees List (row #{row + 1})")
        end
      end
    end
  end

  def validate_custom_export_assessmemts(patients, data, settings, export_file)
    assessments = assessments_by_patient_ids(patients.pluck(:id))
    assessments_sheet = export_file.sheet('Reports')
    assert_equal(assessments.size, assessments_sheet.last_row - 1, 'Number of assessments in Reports List')

    checked = data.dig(:assessments, :checked)

    # Delete this value as it will be replaced with the actual symptom names later on
    checked.delete(:symptoms)

    # Get headers/col names
    headers = checked.map { |field| ImportExport::ASSESSMENT_FIELD_NAMES[field] }
    patients_assessments = patients.joins(assessments: [{ reported_condition: :symptoms }])

    # Add symptom name headers if checked
    if settings.dig(:data, :assessments, :checked).include?(:symptoms)
      symptom_labels = patients_assessments.pluck('symptoms.label').uniq.sort
      headers += symptom_labels.to_a.sort
    end

    # Validate assessment headers
    headers.each_with_index do |header, col|
      assert_equal(header, assessments_sheet.cell(1, col + 1), "For header: #{header} in Reports")
    end

    # Validate assessment cells
    assessment_row = 0
    patients.find_each do |patient|
      patient.assessments.find_each do |assessment|
        # Get basic field data that is checked
        assessment_summary_arr = checked.map do |field|
          if PATIENT_FIELD_TYPES[:alternative_identifiers].include?(field)
            patient[field]
          else
            assessment[field]
          end
        end

        # Get symmptom data if checked
        if settings.dig(:data, :assessments, :checked).include?(:symptoms)
          symptoms_hash = assessment.reported_condition.symptoms.map { |symptom| [symptom[:label], symptom.value] }.to_h
          symptoms_arr = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s || '' }
          assessment_summary_arr.concat(symptoms_arr)
        end

        assessment_summary_arr.each_with_index do |value, col|
          cell_value = assessments_sheet.cell(assessment_row + 2, col + 1)
          assert_equal(value.to_s, cell_value || '', "For field: #{headers[col]} in Reports")
        end
        assessment_row += 1
      end
    end
  end

  def validate_custom_export_vaccines(patients, data, _settings, export_file)
    vaccines = vaccines_by_patient_ids(patients.pluck(:id))
    vaccines_sheet = export_file.sheet('Vaccinations')
    assert_equal(vaccines.size, vaccines_sheet.last_row - 1, 'Number of vaccines in Vaccinations List')

    checked = data.dig(:vaccines, :checked)

    # Validate vaccine headers
    headers = checked.map { |field| ImportExport::VACCINE_FIELD_NAMES[field] }
    headers.each_with_index do |header, col|
      assert_equal(header, vaccines_sheet.cell(1, col + 1), "For header: #{header} in Vaccines")
    end

    # Validate vaccine cells
    vaccine_row = 0
    patients.find_each do |patient|
      patient.vaccines.find_each do |vaccine|
        # Get basic field data that is checked
        vaccine_summary_arr = checked.map do |field|
          if PATIENT_FIELD_TYPES[:alternative_identifiers].include?(field)
            patient[field]
          else
            vaccine[field]
          end
        end

        vaccine_summary_arr.each_with_index do |value, col|
          cell_value = vaccines_sheet.cell(vaccine_row + 2, col + 1)
          assert_equal(value.to_s, cell_value || '', "For field: #{headers[col]} in Vaccinations")
        end
        vaccine_row += 1
      end
    end
  end

  def download_export_files(user, export_type)
    sleep(2) # wait for export and download to complete
    Download.where(user_id: user.id, export_type: export_type.to_s).where('created_at > ?', 10.seconds.ago).find_each do |download|
      visit rails_storage_proxy_url(download.export_files.first)
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
      sleep(DOWNLOAD_CHECK_INTERVAL) until Dir.glob(File.join(SystemTestUtils::DOWNLOAD_PATH, file_name_glob)).any?
    end
    Dir.glob(File.join(SystemTestUtils::DOWNLOAD_PATH, file_name_glob))&.first
  end
end
