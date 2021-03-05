# frozen_string_literal: true

# Helper methods for the import and export controllers
module ImportExport # rubocop:todo Metrics/ModuleLength
  include ImportExportConstants
  include ValidationHelper
  include PatientQueryHelper
  include AssessmentQueryHelper
  include LaboratoryQueryHelper
  include CloseContactQueryHelper
  include TransferQueryHelper
  include HistoryQueryHelper
  include Utils
  include ExcelSanitizer

  # Writes export data to file(s)
  def write_export_data_to_files(config, patients, outer_batch_size, inner_batch_size)
    case config[:format]
    when 'csv'
      csv_export(config, patients, outer_batch_size, inner_batch_size)
    when 'xlsx'
      xlsx_export(config, patients, outer_batch_size, inner_batch_size)
    end
  end

  # Creates a list of csv files from exported data
  def csv_export(config, patients, outer_batch_size, inner_batch_size)
    files = []

    # Determine selected data types for export
    data_types = CUSTOM_EXPORT_OPTIONS.keys.select { |data_type| config.dig(:data, data_type, :checked).present? }

    # Get all of the field data based on the config
    field_data = get_field_data(config, patients)

    # Declare variables in scope outside of batch loop
    csvs = nil
    packages = nil
    inner_batch_iterations_per_outer_batch = outer_batch_size / inner_batch_size
    total_inner_batches = (patients.size / inner_batch_size.to_f).ceil

    # NOTE: in_batches appears to NOT sort within batches, so explicit ordering on ID is also done deeper down.
    # The reorder('') here allows this ordering done later on to work properly.
    patients.reorder('').in_batches(of: inner_batch_size).each_with_index do |batch_group, inner_batch_index|
      # 1) Create CSV files on the first inner batch iteration of each outer batch. If `outer_batch_size` is 10,000 and `inner_batch_size` is 100,
      #    then this will create a new CSV every 100 batches, therefore handling the outer batching.
      if (inner_batch_index % inner_batch_iterations_per_outer_batch).zero?
        # One file for all data types, each data type in a different tab
        csvs = {}
        packages = {}
        data_types.each do |data_type|
          # Create CSV with column headers
          package = CSV.generate(headers: true) do |csv|
            csv << field_data.dig(data_type, :headers)
            csvs[data_type] = csv
          end
          packages[data_type] = package
        end
      end

      # 2) Get export data in batches to decrease size of export data hash maintained in memory
      exported_data = get_export_data(batch_group.order(:id), config[:data])
      data_types.each do |data_type|
        exported_data[data_type]&.each do |record|
          csvs[data_type] << field_data[data_type][:checked].map { |field| record[field] }
        end
      end

      # 3) Check if the next inner_batch_index is the start of a new outer batch or if this current batch is the final batch
      #    If so, save files to db as this is the end of the current outer batch
      next unless ((inner_batch_index + 1) % inner_batch_iterations_per_outer_batch).zero? || inner_batch_index == total_inner_batches - 1

      outer_batch_index = inner_batch_index * inner_batch_size / outer_batch_size
      data_types.each do |data_type|
        file = { filename: build_export_filename(config, data_type, outer_batch_index, false), content: Base64.encode64(packages[data_type]) }
        files << save_file(config, file)
      end
    end

    files
  end

  # Creates a list of excel files from exported data
  def xlsx_export(config, patients, outer_batch_size, inner_batch_size)
    files = []
    separate_files = config[:separate_files].present?

    # Determine selected data types for export
    data_types = CUSTOM_EXPORT_OPTIONS.keys.select { |data_type| config.dig(:data, data_type, :checked).present? }

    # Get all of the field data based on the config
    field_data = get_field_data(config, patients)

    # Declare variables in scope outside of batch loop
    workbooks = nil if separate_files
    workbook = nil unless separate_files
    sheets = nil
    last_row_nums = nil
    inner_batch_iterations_per_outer_batch = outer_batch_size / inner_batch_size
    total_inner_batches = (patients.size / inner_batch_size.to_f).ceil

    # NOTE: in_batches appears to NOT sort within batches, so explicit ordering on ID is also done deeper down.
    # The reorder('') here allows this ordering done later on to work properly.
    patients.reorder('').in_batches(of: inner_batch_size).each_with_index do |batch_group, inner_batch_index|
      # 1) Create excel file(s) on the first inner batch iteration of each outer batch. If `outer_batch_size` is 10,000 and `inner_batch_size` is 100,
      #    then this will create a new excel file(s) every 100 batches, therefore handling the outer batching.
      if (inner_batch_index % inner_batch_iterations_per_outer_batch).zero?
        # One file for all data types, each data type in a different tab
        workbooks = {} if separate_files
        workbook = FastExcel.open(constant_memory: true) unless separate_files
        sheets = {}
        last_row_nums = {}
        data_types.each do |data_type|
          workbook = FastExcel.open(constant_memory: true) if separate_files
          worksheet = workbook.add_worksheet(config.dig(:data, data_type, :tab) || CUSTOM_EXPORT_OPTIONS.dig(data_type, :label))
          worksheet.auto_width = true
          worksheet.append_row(field_data.dig(data_type, :headers))
          last_row_nums[data_type] = 0
          sheets[data_type] = worksheet
          workbooks[data_type] = workbook if separate_files
        end
      end

      # 2) Get export data in batches to decrease size of export data hash maintained in memory
      exported_data = get_export_data(batch_group.order(:id), config[:data])
      data_types.each do |data_type|
        last_row_nums[data_type] = write_xlsx_rows(exported_data, data_type, sheets[data_type], field_data[data_type][:checked], last_row_nums[data_type])
      end

      # 3) Check if the next inner_batch_index is the start of a new outer batch or if this current batch is the final batch
      #    If so, save files to db as this is the end of the current outer batch
      next unless ((inner_batch_index + 1) % inner_batch_iterations_per_outer_batch).zero? || inner_batch_index == total_inner_batches - 1

      outer_batch_index = inner_batch_index * inner_batch_size / outer_batch_size
      if separate_files
        data_types.each do |data_type|
          file = { filename: build_export_filename(config, data_type, outer_batch_index, false), content: Base64.encode64(workbooks[data_type].read_string) }
          files << save_file(config, file)
        end
      else
        file = { filename: build_export_filename(config, nil, outer_batch_index, false), content: Base64.encode64(workbook.read_string) }
        files << save_file(config, file)
      end
    end

    files
  end

  # Gets data for this batch of patients that may not have already been present in the export config (such as specific symptoms).
  def get_field_data(config, patients)
    data = config[:data].deep_dup

    # Update the checked data (used for obtaining values) with race information
    update_checked_race_data(data)

    # Update the header data (used for obtaining column names)
    update_headers(data)

    # Update the checked and header data for assessment symptoms
    # NOTE: this must be done after updating the general headers above
    update_assessment_symptom_data(data, patients)

    data
  end

  # Finds the race values that should be included if the Race (All Race Fields) option is checked in custom export
  def update_checked_race_data(data)
    # Don't update if patient data isn't needed or race data isn't checked
    return unless data.dig(:patients, :checked)&.include?(:race)

    # Replace race field with actual race fields
    race_index = data[:patients][:checked].index(:race)
    data[:patients][:checked].delete(:race)
    data[:patients][:checked].insert(race_index, *PATIENT_FIELD_TYPES[:races])
  end

  # Update the header data (used for obtaining column names)
  def update_headers(data)
    # Populate the headers if they're not already set (which is the case with the custom exports)
    CUSTOM_EXPORT_OPTIONS.each_key do |data_type|
      next unless data.dig(data_type, :checked).present? && data.dig(data_type, :headers).blank?

      data[data_type][:headers] = data[data_type][:checked].map { |field| ALL_FIELDS_NAMES.dig(data_type, field) }
    end
  end

  # Finds the symptoms needed for the reports columns
  def update_assessment_symptom_data(data, patients)
    # Don't update if assessment symptom data isn't needed
    return unless data.dig(:assessments, :checked)&.include?(:symptoms)

    data[:assessments][:checked].delete(:symptoms)
    data[:assessments][:headers].delete('Symptoms Reported')

    # Nested querying by id is faster than joining patients to assessments to conditions to symptoms
    symptoms = Symptom.where(condition_id: ReportedCondition.where(assessment_id: Assessment.where(patient_id: patients.pluck(:id)).pluck(:id)).pluck(:id))
    symptom_names_and_labels = symptoms.distinct.order(:label).pluck(:name, :label).transpose

    # Empty symptoms check
    return unless symptom_names_and_labels.present?

    data[:assessments][:checked].concat(symptom_names_and_labels.first.map(&:to_sym))
    data[:assessments][:headers].concat(symptom_names_and_labels.second)
  end

  # Gets all associated relevant data for patients group based on queries and fields
  def get_export_data(patients, data)
    exported_data = {}
    exported_data[:patients] = extract_patients_details(patients, data[:patients][:checked]) if data.dig(:patients, :checked).present?

    # extract patient identifiers for other data types if necessary
    if data.dig(:assessments, :checked).present? || data.dig(:laboratories, :checked).present? || data.dig(:close_contacts, :checked).present? ||
       data.dig(:transfers, :checked).present? || data.dig(:histories, :checked).present?
      # extract patient identifiers from exported data if it already exists otherwise perform query to pluck those values
      if exported_data[:patients].present? && (PATIENT_FIELD_TYPES[:alternative_identifiers] - data[:patients][:checked]).empty?
        patients_identifiers = Hash[exported_data[:patients].map do |patient_details|
                                      [patient_details[:id], {
                                        user_defined_id_statelocal: patient_details[:user_defined_id_statelocal],
                                        user_defined_id_cdc: patient_details[:user_defined_id_cdc],
                                        user_defined_id_nndss: patient_details[:user_defined_id_nndss]
                                      }]
                                    end]
      else
        patients_identifiers = Hash[patients.pluck(:id, :user_defined_id_statelocal, :user_defined_id_cdc, :user_defined_id_nndss)
                                            .map do |id, statelocal, cdc, nndss|
                                              [id, { user_defined_id_statelocal: statelocal, user_defined_id_cdc: cdc, user_defined_id_nndss: nndss }]
                                            end]
      end
    end

    if data.dig(:assessments, :checked).present?
      assessments = assessments_by_patient_ids(patients_identifiers.keys)
      exported_data[:assessments] = extract_assessments_details(patients_identifiers, assessments, data[:assessments][:checked])
    end

    if data.dig(:laboratories, :checked).present?
      laboratories = laboratories_by_patient_ids(patients_identifiers.keys)
      exported_data[:laboratories] = extract_laboratories_details(patients_identifiers, laboratories, data[:laboratories][:checked])
    end

    if data.dig(:close_contacts, :checked).present?
      close_contacts = close_contacts_by_patient_ids(patients_identifiers.keys)
      exported_data[:close_contacts] = extract_close_contacts_details(patients_identifiers, close_contacts, data[:close_contacts][:checked])
    end

    if data.dig(:transfers, :checked).present?
      transfers = transfers_by_patient_ids(patients_identifiers.keys)
      exported_data[:transfers] = extract_transfers_details(patients_identifiers, transfers, data[:transfers][:checked])
    end

    if data.dig(:histories, :checked).present?
      histories = histories_by_patient_ids(patients_identifiers.keys)
      exported_data[:histories] = extract_histories_details(patients_identifiers, histories, data[:histories][:checked])
    end

    exported_data
  end

  # Extract patient data values given relevant fields
  def extract_patients_details(patients, fields)
    # query jurisdiction paths in bulk if requested
    if (fields & %i[jurisdiction_path transferred_from transferred_to]).any?
      jur_ids = patients.pluck(:jurisdiction_id).uniq
      jur_ids = (jur_ids + patients.pluck(:latest_transfer_from)).uniq if fields.include?(:transferred_from)
      jurisdiction_paths = Hash[Jurisdiction.find(jur_ids).pluck(:id, :path)]
    end

    # query jurisdiction names in bulk if requested
    jurisdiction_names = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :name)] if fields.include?(:jurisdiction_name)

    # query user emails in bulk if requested
    patients_creators = Hash[patients.joins('INNER JOIN users ON patients.creator_id = users.id').pluck('users.id', 'users.email')] if fields.include?(:creator)

    # query patients laboratories in bulk if requested
    if (fields & PATIENT_FIELD_TYPES[:lab_fields]).any?
      patients_laboratories = Laboratory.where(patient_id: patients.pluck(:id))
                                        .order(specimen_collection: :desc)
                                        .group_by(&:patient_id)
                                        .transform_values { |v| v.take(2) }
    end

    # construct patient details
    patients.map do |patient|
      patient_details = {}

      # populate inherent fields by type
      (fields & PATIENT_FIELD_TYPES[:strings]).each { |field| patient_details[field] = remove_formula_start(patient[field]) }
      (fields & PATIENT_FIELD_TYPES[:dates]).each { |field| patient_details[field] = patient[field]&.strftime('%F') }
      (fields & PATIENT_FIELD_TYPES[:phones]).each { |field| patient_details[field] = format_phone_number(patient[field]) }
      (fields & (PATIENT_FIELD_TYPES[:numbers] + PATIENT_FIELD_TYPES[:timestamps])).each { |field| patient_details[field] = patient[field] }
      (fields & (PATIENT_FIELD_TYPES[:booleans] + PATIENT_FIELD_TYPES[:races])).each { |field| patient_details[field] = patient[field] || false }

      # populate all races if race field is selected
      PATIENT_FIELD_TYPES[:races].each { |field| patient_details[field] = patient[field] || false } if fields.include?(:race)

      # populate computed fields
      patient_details[:name] = patient.displayed_name if fields.include?(:name)
      patient_details[:age] = patient.calc_current_age if fields.include?(:age)
      patient_details[:workflow] = patient[:isolation] ? 'Isolation' : 'Exposure'
      patient_details[:symptom_onset_defined_by] = patient[:user_defined_symptom_onset] ? 'User' : 'System'
      patient_details[:monitoring_status] = patient[:monitoring] ? 'Actively Monitoring' : 'Not Monitoring'
      patient_details[:end_of_monitoring] = patient.end_of_monitoring if fields.include?(:end_of_monitoring)
      patient_details[:expected_purge_ts] = patient.expected_purge_date_exp if fields.include?(:expected_purge_ts)
      patient_details[:full_status] = patient.status&.to_s&.humanize&.downcase if fields.include?(:full_status)
      patient_details[:status] = patient.status&.to_s&.humanize&.downcase&.sub('exposure ', '')&.sub('isolation ', '') if fields.include?(:status)

      # populate creator if requested
      patient_details[:creator] = patients_creators[patient.creator_id] if fields.include?(:creator)

      # populate jurisdiction if requested
      patient_details[:jurisdiction_name] = jurisdiction_names[patient.jurisdiction_id] if fields.include?(:jurisdiction_name)
      patient_details[:jurisdiction_path] = jurisdiction_paths[patient.jurisdiction_id] if fields.include?(:jurisdiction_path)

      # populate latest transfer from and to if requested
      if patient[:latest_transfer_from].present?
        patient_details[:transferred_from] = jurisdiction_paths[patient.latest_transfer_from] if fields.include?(:transferred_from)
        patient_details[:transferred_to] = jurisdiction_paths[patient.jurisdiction_id] if fields.include?(:transferred_to)
      end

      # populate labs if requested
      if patients_laboratories&.key?(patient.id)
        if patients_laboratories[patient.id]&.first&.present?
          patient_details[:lab_1_type] = patients_laboratories[patient.id].first[:lab_type] if fields.include?(:lab_1_type)
          if fields.include?(:lab_1_specimen_collection)
            patient_details[:lab_1_specimen_collection] = patients_laboratories[patient.id].first[:specimen_collection]&.strftime('%F')
          end
          patient_details[:lab_1_report] = patients_laboratories[patient.id].first[:report]&.strftime('%F') if fields.include?(:lab_1_report)
          patient_details[:lab_1_result] = patients_laboratories[patient.id].first[:result] if fields.include?(:lab_1_result)
        end
        if patients_laboratories[patient.id]&.second&.present?
          patient_details[:lab_2_type] = patients_laboratories[patient.id].second[:lab_type] if fields.include?(:lab_2_type)
          if fields.include?(:lab_2_specimen_collection)
            patient_details[:lab_2_specimen_collection] = patients_laboratories[patient.id].second[:specimen_collection]&.strftime('%F')
          end
          patient_details[:lab_2_report] = patients_laboratories[patient.id].second[:report]&.strftime('%F') if fields.include?(:lab_2_report)
          patient_details[:lab_2_result] = patients_laboratories[patient.id].second[:result] if fields.include?(:lab_2_result)
        end
      end

      patient_details
    end
  end

  # Extract assessment data values given relevant fields
  def extract_assessments_details(patients_identifiers, assessments, fields)
    assessments_details = assessments.map do |assessment|
      assessment.custom_details(fields).merge(patients_identifiers[assessment.patient_id])
    end

    # query assessment symptoms if requested
    if fields.include?(:symptoms)
      assessment_ids = assessments_details.map { |assessment_details| assessment_details[:id] }

      # initialize hash for mapping assessments to symptoms
      symptoms = Hash[assessment_ids.map { |assessment_id| [assessment_id, {}] }]

      # compute symptom value directly in database by selecting the correct value field and casting it as a string for export for optimal performance
      # NOTE: this prevents symptom type, bool_value, int_value, and float_value fields to need to be loaded into memory
      #       while maintaining performance speed by fetching all symptom values in a single query
      symptom_value = Arel.sql("CASE WHEN symptoms.type = 'BoolSymptom' THEN CASE WHEN symptoms.bool_value THEN 'true' ELSE 'false' END
                                     WHEN symptoms.type = 'IntegerSymptom' THEN CAST(symptoms.int_value AS CHAR)
                                     WHEN symptoms.type = 'FloatSymptom' THEN CAST(symptoms.float_value AS CHAR)
                                     ELSE ''
                                END")

      # save symptom values to hash mapping assessments to symptoms
      ReportedCondition.where(assessment_id: assessment_ids)
                       .joins(:symptoms)
                       .pluck(:assessment_id, :name, symptom_value)
                       .each { |(id, name, value)| symptoms[id][name.to_sym] = value }

      # add symptoms to assessment details
      assessments_details = assessments_details.map do |assessment_details|
        assessment_details.merge(symptoms[assessment_details[:id]])
      end
    end

    assessments_details
  end

  # Extract laboratory data values given relevant fields
  def extract_laboratories_details(patients_identifiers, laboratories, fields)
    laboratories.map { |laboratory| laboratory.custom_details(fields).merge(patients_identifiers[laboratory.patient_id]) }
  end

  # Extract close contact data values given relevant fields
  def extract_close_contacts_details(patients_identifiers, close_contacts, fields)
    close_contacts.map { |close_contact| close_contact.custom_details(fields).merge(patients_identifiers[close_contact.patient_id]) }
  end

  # Extract transfer data values given relevant fields
  def extract_transfers_details(patients_identifiers, transfers, fields)
    user_emails = Hash[User.find(transfers.map(&:who_id).uniq).pluck(:id, :email)]
    jurisdiction_ids = [transfers.map(&:from_jurisdiction_id), transfers.map(&:to_jurisdiction_id)].flatten.uniq
    jurisdiction_paths = Hash[Jurisdiction.find(jurisdiction_ids).pluck(:id, :path)]
    transfers.map { |transfer| transfer.custom_details(fields, user_emails, jurisdiction_paths).merge(patients_identifiers[transfer.patient_id]) }
  end

  # Extract history data values given relevant fields
  def extract_histories_details(patients_identifiers, histories, fields)
    histories.map { |history| history.custom_details(fields).merge(patients_identifiers[history.patient_id]) }
  end

  # Write exported data of data_type to worksheet
  def write_xlsx_rows(exported_data, data_type, worksheet, fields, last_row_num)
    exported_data[data_type]&.each do |record|
      # fast_excel unfortunately does not provide a method to modify the @last_row_number class variable so it needs to be manually kept track of
      last_row_num += 1
      fields.each_with_index do |field, col_index|
        # write_string is used instead of append_row because append_row does not provide the capability to write data to excel files simply formatted as strings
        # calling write_string directly is also more performant because is skips all the unnecessary logic in write_value that tries to detect each value type
        worksheet.write_string(last_row_num, col_index, record[field].to_s, nil)
      end
    end
    last_row_num
  end

  # Builds a file name using the base name, index, date, and extension.
  # Ex: "Sara-Alert-Linelist-Isolation-2020-09-01T14:15:05-04:00-1"
  def build_export_filename(config, data_type, index, glob)
    return unless config[:export_type].present? && EXPORT_TYPES.key?(config[:export_type])

    if config[:filename_data_type].present? && data_type.present? && CUSTOM_EXPORT_OPTIONS[data_type].present?
      data_type_name = config.dig(:data, data_type, :name) || CUSTOM_EXPORT_OPTIONS.dig(data_type, :label)&.gsub(' ', '-')
    end
    base_name = "#{EXPORT_TYPES.dig(config[:export_type], :filename)}#{data_type_name ? "-#{data_type_name}" : ''}"
    timestamp = glob ? '????-??-??T??_??_?????_??' : DateTime.now
    "#{base_name}-#{timestamp}#{index.present? ? "-#{index + 1}" : ''}.#{config[:format]}"
  end

  # Write file and create lookup
  def save_file(config, file)
    lookup = SecureRandom.uuid
    if ActiveRecord::Base.logger.formatter.nil?
      download = Download.insert(user_id: config[:user_id], export_type: config[:export_type], filename: file[:filename],
                                 lookup: lookup, contents: file[:content], created_at: DateTime.now, updated_at: DateTime.now)
    else
      ActiveRecord::Base.logger.silence do
        download = Download.insert(user_id: config[:user_id], export_type: config[:export_type], filename: file[:filename],
                                   lookup: lookup, contents: file[:content], created_at: DateTime.now, updated_at: DateTime.now)
      end
    end
    { lookup: lookup, filename: file[:filename] }
  end
end
