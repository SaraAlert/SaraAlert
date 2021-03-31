# frozen_string_literal: true

# Helper methods for the import and export controllers
module ImportExport # rubocop:todo Metrics/ModuleLength
  include ImportExportConstants
  include ValidationHelper
  include PatientQueryHelper
  include AssessmentQueryHelper
  include LaboratoryQueryHelper
  include VaccineQueryHelper
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
    field_data, symptom_names = get_field_data(config, patients)

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
      exported_data = get_export_data(batch_group.order(:id), config[:data], field_data, symptom_names)
      data_types.each do |data_type|
        exported_data[data_type]&.each { |record| csvs[data_type] << record }
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
    field_data, symptom_names = get_field_data(config, patients)

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
      exported_data = get_export_data(batch_group.order(:id), config[:data], field_data, symptom_names)
      data_types.each do |data_type|
        exported_data[data_type]&.each do |record|
          # fast_excel unfortunately does not provide a method to modify the @last_row_number class variable so it needs to be manually kept track of
          last_row_nums[data_type] += 1
          record.each_with_index do |value, col_index|
            sheets[data_type].write_string(last_row_nums[data_type], col_index, value.to_s, nil)
          end
        end
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
    symptom_names = update_assessment_symptom_data(data, patients)

    [data, symptom_names]
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
    return [] unless symptom_names_and_labels.present?

    data[:assessments][:checked].concat(symptom_names_and_labels.first.map(&:to_sym))
    data[:assessments][:headers].concat(symptom_names_and_labels.second)

    symptom_names_and_labels.first.map(&:to_sym)
  end

  # Gets all associated relevant data for patients group based on queries and fields
  def get_export_data(patients, data, field_data, symptom_names)
    exported_data = {}
    exported_data[:patients] = extract_patients_details(patients, field_data[:patients][:checked]) if data.dig(:patients, :checked).present?

    # extract patient identifiers for other data types if necessary
    if exported_data[:patients].present? && data[:patients][:checked].include?(:id)
      id_index = field_data[:patients][:checked].index(:id)
      patient_ids = exported_data[:patients].map { |values| values[id_index] }
    else
      patient_ids = patients.pluck(:id)
    end

    if data.dig(:assessments, :checked).present?
      assessments = assessments_by_patient_ids(patient_ids)
      symptom_names = field_data[:assessments][:checked] - data[:assessments][:checked]
      exported_data[:assessments] = extract_assessments_details(assessments, data[:assessments][:checked], symptom_names)
    end

    if data.dig(:laboratories, :checked).present?
      laboratories = laboratories_by_patient_ids(patient_ids)
      exported_data[:laboratories] = extract_laboratories_details(laboratories, data[:laboratories][:checked])
    end

    if data.dig(:vaccines, :checked).present?
      vaccines = vaccines_by_patient_ids(patient_ids)
      exported_data[:vaccines] = extract_vaccines_details(vaccines, data[:vaccines][:checked])
    end

    if data.dig(:close_contacts, :checked).present?
      close_contacts = close_contacts_by_patient_ids(patient_ids)
      exported_data[:close_contacts] = extract_close_contacts_details(close_contacts, data[:close_contacts][:checked])
    end

    if data.dig(:transfers, :checked).present?
      transfers = transfers_by_patient_ids(patient_ids)
      exported_data[:transfers] = extract_transfers_details(transfers, data[:transfers][:checked])
    end

    if data.dig(:histories, :checked).present?
      histories = histories_by_patient_ids(patient_ids)
      exported_data[:histories] = extract_histories_details(histories, data[:histories][:checked])
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
    patients_creators = Hash[patients.joins('JOIN users ON patients.creator_id = users.id').pluck('users.id', 'users.email')] if fields.include?(:creator)

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

      # populate computed fields
      patient_details[:name] = patient.displayed_name if fields.include?(:name)
      patient_details[:age] = patient.calc_current_age if fields.include?(:age)
      patient_details[:workflow] = patient[:isolation] ? 'Isolation' : 'Exposure'
      patient_details[:symptom_onset_defined_by] = patient[:user_defined_symptom_onset] ? 'User' : 'System'
      patient_details[:no_symptom_history] = patient[:symptom_onset].nil?.to_s
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

      fields.map { |field| patient_details[field] }
    end
  end

  # Extract assessment data values given relevant fields
  def extract_assessments_details(assessments, fields, symptom_names)
    # validate fields to be plucked and do not include 'symptoms' as it is not an actual field
    plucked_fields = fields & (ASSESSMENT_FIELD_NAMES.keys - [:symptoms])

    # modify query to include symptoms if selected
    if fields.include?(:symptoms)
      # include necessary joins and group by plucked fields because all non aggregated fields in the select statement must also appear in the group by clause
      # query must always include assessment_id in group by clause (since full history export does not include it)
      assessments = assessments.joins(reported_condition: :symptoms).group(*(plucked_fields | [:assessment_id]))

      # this sql statement casts symptom values into their string value so all symptom values can be represented in a single column
      string_value = ActiveRecord::Base.sanitize_sql(Arel.sql("CASE WHEN symptoms.type = 'BoolSymptom' THEN CASE WHEN bool_value THEN 'true' ELSE 'false' END
                                                                    WHEN symptoms.type = 'IntegerSymptom' THEN CAST(int_value AS CHAR)
                                                                    WHEN symptoms.type = 'FloatSymptom' THEN CAST(float_value AS CHAR)
                                                                    ELSE '' END"))

      # add each unique symptom value to the list of fields to pluck
      plucked_fields += symptom_names.map do |name|
        name = ActiveRecord::Base.sanitize_sql(name)
        Arel.sql("MAX(CASE WHEN symptoms.name = '#{name}' THEN (#{string_value}) END) AS '#{name}'")
      end
    end

    # join patients if any alternative identifiers are selected
    assessments = assessments.joins(:patient) if (fields & PATIENT_FIELD_TYPES[:alternative_identifiers]).any?

    # pluck selected fields
    records = assessments.pluck(*plucked_fields)

    # ensure that records is always a 2d array
    records = records.map { |record| [record] } if plucked_fields.size == 1

    # remove formula start for who_reported field
    (fields & %i[who_reported]).map { |field| fields.index(field) }
                               .each { |index| records.each { |values| values[index] = remove_formula_start(values[index]) } }

    records
  end

  # Extract laboratory data values given relevant fields
  def extract_laboratories_details(laboratories, fields)
    # join patients if any alternative identifiers are selected
    laboratories = laboratories.joins(:patient) if (fields & PATIENT_FIELD_TYPES[:alternative_identifiers]).any?

    # validate and pluck selected fields
    plucked_fields = fields & LABORATORY_FIELD_NAMES.keys
    records = laboratories.pluck(*plucked_fields)

    # ensure that records is always a 2d array
    records = records.map { |record| [record] } if plucked_fields.size == 1

    records
  end

  # Extract vaccine data values given relevant fields
  def extract_vaccines_details(vaccines, fields)
    # join patients if any alternative identifiers are selected
    vaccines = vaccines.joins(:patient) if (fields & PATIENT_FIELD_TYPES[:alternative_identifiers]).any?

    # validate and pluck selected fields
    plucked_fields = fields & VACCINE_FIELD_NAMES.keys
    records = vaccines.pluck(*plucked_fields)

    # ensure that records is always a 2d array
    records = records.map { |record| [record] } if plucked_fields.size == 1

    # remove formula start for 'notes' field
    (fields & %i[notes]).map { |field| fields.index(field) }
                        .each { |index| records.each { |values| values[index] = remove_formula_start(values[index]) } }

    records
  end

  # Extract close contact data values given relevant fields
  def extract_close_contacts_details(close_contacts, fields)
    # join patients if any alternative identifiers are selected
    close_contacts = close_contacts.joins(:patient) if (fields & PATIENT_FIELD_TYPES[:alternative_identifiers]).any?

    # validate and pluck selected fields
    plucked_fields = fields & CLOSE_CONTACT_FIELD_NAMES.keys
    records = close_contacts.pluck(*plucked_fields)

    # ensure that records is always a 2d array
    records = records.map { |record| [record] } if plucked_fields.size == 1

    # remove formula start for 'created_by' and 'comment' fields
    (fields & %i[first_name last_name email notes]).map { |field| fields.index(field) }
                                                   .each { |index| records.each { |values| values[index] = remove_formula_start(values[index]) } }

    # format phone numbers for 'primary_telephone' field
    (fields & %i[primary_telephone]).map { |field| fields.index(field) }
                                    .each { |index| records.each { |values| values[index] = format_phone_number(values[index]) } }

    records
  end

  # Extract transfer data values given relevant fields
  def extract_transfers_details(transfers, fields)
    # validate fields to be plucked
    plucked_fields = fields & TRANSFER_FIELD_NAMES.keys

    # join patients if any alternative identifiers are selected
    transfers = transfers.joins(:patient) if (fields & PATIENT_FIELD_TYPES[:alternative_identifiers]).any?

    # join users if 'who' is selected and replace field with user email
    if fields.include?(:who)
      transfers = transfers.joins('JOIN users ON transfers.who_id = users.id')
      plucked_fields[plucked_fields.index(:who)] = 'users.email'
    end

    # join jurisdictions if 'from_jurisdiction' is selected and replace field with jurisdiction path
    if fields.include?(:from_jurisdiction)
      transfers = transfers.joins('JOIN jurisdictions j_from ON transfers.from_jurisdiction_id = j_from.id')
      plucked_fields[plucked_fields.index(:from_jurisdiction)] = 'j_from.path'
    end

    # join jurisdictions if 'to_jurisdiction' is selected and replace field with jurisdiction path
    if fields.include?(:to_jurisdiction)
      transfers = transfers.joins('JOIN jurisdictions j_to ON transfers.to_jurisdiction_id = j_to.id')
      plucked_fields[plucked_fields.index(:to_jurisdiction)] = 'j_to.path'
    end

    # pluck selected fields
    records = transfers.pluck(*plucked_fields)

    # ensure that records is always a 2d array
    records = records.map { |record| [record] } if plucked_fields.size == 1

    records
  end

  # Extract history data values given relevant fields
  def extract_histories_details(histories, fields)
    # join patients if any alternative identifiers are selected
    histories = histories.joins(:patient) if (fields & PATIENT_FIELD_TYPES[:alternative_identifiers]).any?

    # validate and pluck selected fields
    plucked_fields = fields & HISTORY_FIELD_NAMES.keys
    records = histories.pluck(*plucked_fields)

    # ensure that records is always a 2d array
    records = records.map { |record| [record] } if plucked_fields.size == 1

    # remove formula start for 'created_by' and 'comment' fields
    (fields & %i[created_by comment]).map { |field| fields.index(field) }
                                     .each { |index| records.each { |values| values[index] = remove_formula_start(values[index]) } }

    records
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
