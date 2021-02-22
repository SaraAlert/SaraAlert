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
    field_data = get_field_data(config)

    # Declare variables in scope outside of batch loop
    csvs = nil
    packages = nil
    total_inner_batches = (patients.size / inner_batch_size.to_f).ceil

    # NOTE: in_batches appears to NOT sort within batches, so explicit ordering on ID is also done deeper down.
    # The reorder('') here allows this ordering done later on to work properly.
    patients.reorder('').in_batches(of: inner_batch_size).each_with_index do |batch_group, inner_batch_index|
      # 1) Create file(s) for new batch
      if (inner_batch_index % (outer_batch_size / inner_batch_size)).zero?
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

      # 3) Save files to db at the end of each outer batch
      next unless ((inner_batch_index + 1) % (outer_batch_size / inner_batch_size)).zero? || inner_batch_index == total_inner_batches - 1

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
    field_data = get_field_data(config)

    # Declare variables in scope outside of batch loop
    workbooks = nil if separate_files
    workbook = nil unless separate_files
    sheets = nil
    last_row_nums = nil
    total_inner_batches = (patients.size / inner_batch_size.to_f).ceil

    # NOTE: in_batches appears to NOT sort within batches, so explicit ordering on ID is also done deeper down.
    # The reorder('') here allows this ordering done later on to work properly.
    patients.reorder('').in_batches(of: inner_batch_size).each_with_index do |batch_group, inner_batch_index|
      # 1) Create file(s) for new batch
      if (inner_batch_index % (outer_batch_size / inner_batch_size)).zero?
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

      # 3) Save files to db at the end of each outer batch
      next unless ((inner_batch_index + 1) % (outer_batch_size / inner_batch_size)).zero? || inner_batch_index == total_inner_batches - 1

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
  def get_field_data(config)
    data = config[:data].deep_dup

    # Update the checked data (used for obtaining values) with race information
    update_checked_race_data(data)

    # Update the header data (used for obtaining column names)
    update_headers(data)

    # Update the checked and header data for assessment symptoms
    # NOTE: this must be done after updating the general headers above
    update_assessment_symptom_data(data)

    data
  end

  def write_xlsx_rows(exported_data, data_type, worksheet, fields, last_row_num)
    exported_data[data_type]&.each do |record|
      # fast_excel unfortunately does not provide a method to modify the @last_row_number class variable so it needs to be manually kept track of
      last_row_num += 1
      fields.each_with_index do |field, col_index|
        # write_string is used instead of append_row because it does not provide the capability to write data as strings
        worksheet.write_string(last_row_num, col_index, record[field].to_s, nil)
      end
    end
    last_row_num
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

  # Finds the symptoms needed for the reports columns
  def update_assessment_symptom_data(data)
    # Don't update if assessment symptom data isn't needed
    return unless data.dig(:assessments, :checked).present? && data[:assessments][:checked].include?(:symptoms)

    # Using Symptom.all for finding distinct symptom names is actually faster here because it can use symptoms_index_chain_1
    symptom_names = Symptom.all.distinct.pluck(:name).sort
    symptom_labels = symptom_names.map { |name| Symptom.find_by(name: name).label }

    data[:assessments][:checked].delete(:symptoms)
    data[:assessments][:checked].concat(symptom_names.map(&:to_sym))

    data[:assessments][:headers].delete('Symptoms Reported')
    data[:assessments][:headers].concat(symptom_labels)
  end

  # Finds the race values that should be included if the Race (All Race Fields) option is checked in custom export
  def update_checked_race_data(data)
    # Don't update if patient data isn't needed or race data isn't checked
    return unless data.dig(:patients, :checked).present? && data[:patients][:checked].include?(:race)

    # Replace race field with actual race fields
    race_index = data[:patients][:checked].index(:race)
    data[:patients][:checked].delete(:race)
    data[:patients][:checked].insert(race_index, *PATIENT_RACE_FIELDS)
  end

  # Update the header data (used for obtaining column names)
  def update_headers(data)
    # Populate the headers if they're not already set (which is the case with the custom exports)
    CUSTOM_EXPORT_OPTIONS.each_key do |data_type|
      next unless data.dig(data_type, :checked).present? && data.dig(data_type, :headers).blank?

      data[data_type][:headers] = data[data_type][:checked].map { |field| ALL_FIELDS_NAMES.dig(data_type, field) }
    end
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

  # Gets all associated relevant data for patients group based on queries and fields
  def get_export_data(patients, data)
    exported_data = {}
    patients_identifiers = Hash[patients.pluck(:id, :user_defined_id_statelocal, :user_defined_id_cdc, :user_defined_id_nndss)
                                        .map do |id, statelocal, cdc, nndss|
                                          [id, { user_defined_id_statelocal: statelocal, user_defined_id_cdc: cdc, user_defined_id_nndss: nndss }]
                                        end]

    exported_data[:patients] = extract_patients_details(patients, data[:patients][:checked]) if data.dig(:patients, :checked).present?

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

  # Extracts patient data values given relevant fields
  def extract_patients_details(patients, fields)
    # perform the following queries in bulk only if requested for better performance
    if fields.include?(:jurisdiction_name)
      jurisdiction_names = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :name).map { |id, name| [id, name] }]
    end
    if (fields & %i[jurisdiction_path transferred_from transferred_to]).size.positive?
      jur_ids = patients.pluck(:jurisdiction_id).uniq
      jur_ids = (jur_ids + patients.pluck(:latest_transfer_from)).uniq if fields.include?(:transferred_from)
      jurisdiction_paths = Hash[Jurisdiction.find(jur_ids).pluck(:id, :path).map { |id, path| [id, path] }]
    end

    patients_creators = Hash[patients.joins('INNER JOIN users ON patients.creator_id = users.id').pluck('users.id', 'users.email')] if fields.include?(:creator)
    if (fields & PATIENT_LAB_FIELDS).any?
      patients_laboratories = Laboratory.where(patient_id: patients.pluck(:id))
                                        .order(specimen_collection: :desc)
                                        .group_by(&:patient_id)
                                        .transform_values { |v| v.take(2) }
    end

    # construct patient details
    patients_details = []
    patients.each do |patient|
      # populate requested inherent fields
      patient_details = extract_incomplete_patient_details(patient, fields)

      # populate creator if requested
      patient_details[:creator] = patients_creators[patient.creator_id] || '' if fields.include?(:creator)

      # populate jurisdiction if requested
      patient_details[:jurisdiction_name] = jurisdiction_names[patient.jurisdiction_id] || '' if fields.include?(:jurisdiction_name)
      patient_details[:jurisdiction_path] = jurisdiction_paths[patient.jurisdiction_id] || '' if fields.include?(:jurisdiction_path)

      # populate latest transfer from and to if requested
      if patient[:latest_transfer_from].present?
        patient_details[:transferred_from] = jurisdiction_paths[patient.latest_transfer_from]
        patient_details[:transferred_to] = jurisdiction_paths[patient.jurisdiction_id]
      end

      # populate labs if requested
      if patients_laboratories&.key?(patient.id)
        if patients_laboratories[patient.id]&.first&.present?
          patient_details[:lab_1_type] = patients_laboratories[patient.id].first[:lab_type] || '' if fields.include?(:lab_1_type)
          if fields.include?(:lab_1_specimen_collection)
            patient_details[:lab_1_specimen_collection] = patients_laboratories[patient.id].first[:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_1_report] = patients_laboratories[patient.id].first[:report]&.strftime('%F') || '' if fields.include?(:lab_1_report)
          patient_details[:lab_1_result] = patients_laboratories[patient.id].first[:result] || '' if fields.include?(:lab_1_result)
        end
        if patients_laboratories[patient.id]&.second&.present?
          patient_details[:lab_2_type] = patients_laboratories[patient.id].second[:lab_type] || '' if fields.include?(:lab_2_type)
          if fields.include?(:lab_2_specimen_collection)
            patient_details[:lab_2_specimen_collection] = patients_laboratories[patient.id].second[:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_2_report] = patients_laboratories[patient.id].second[:report]&.strftime('%F') || '' if fields.include?(:lab_2_report)
          patient_details[:lab_2_result] = patients_laboratories[patient.id].second[:result] || '' if fields.include?(:lab_2_result)
        end
      end

      patients_details << patient_details
    end

    patients_details
  end

  # Extracts incomplete patient data values given relevant fields
  def extract_incomplete_patient_details(patient, fields)
    patient_details = {}

    (fields & (PATIENT_FIELD_TYPES[:numbers] + PATIENT_FIELD_TYPES[:strings])).each do |field|
      patient_details[field] = patient[field]&.to_s || ''
    end

    (fields & PATIENT_FIELD_TYPES[:dates]).each do |field|
      patient_details[field] = patient[field]&.strftime('%F') || ''
    end

    (fields & PATIENT_FIELD_TYPES[:timestamps]).each do |field|
      patient_details[field] = patient[field] || ''
    end

    (fields & PATIENT_FIELD_TYPES[:booleans]).each do |field|
      patient_details[field] = (patient[field] || false).to_s
    end

    (fields & PATIENT_FIELD_TYPES[:phones]).each do |field|
      patient_details[field] = format_phone_number(patient[field])
    end

    PATIENT_RACE_FIELDS.each { |race| patient_details[race] = patient[race] || false } if fields.include?(:race)

    patient_details[:name] = patient.displayed_name if fields.include?(:name)
    patient_details[:age] = patient.calc_current_age if fields.include?(:age)
    patient_details[:workflow] = patient[:isolation] ? 'Isolation' : 'Exposure'
    patient_details[:symptom_onset_defined_by] = patient[:user_defined_symptom_onset] ? 'User' : 'System'
    patient_details[:monitoring_status] = patient[:monitoring] ? 'Actively Monitoring' : 'Not Monitoring'
    patient_details[:end_of_monitoring] = patient.end_of_monitoring || '' if fields.include?(:end_of_monitoring)
    patient_details[:expected_purge_ts] = patient.expected_purge_date_exp || '' if fields.include?(:expected_purge_ts)
    patient_details[:full_status] = patient.status&.to_s&.humanize&.downcase || '' if fields.include?(:full_status)
    patient_details[:status] = patient.status&.to_s&.humanize&.downcase&.gsub('exposure ', '')&.gsub('isolation ', '') || '' if fields.include?(:status)

    patient_details
  end

  # Extracts assessment data values given relevant fields
  def extract_assessments_details(patients_identifiers, assessments, fields)
    if fields.include?(:symptoms)
      conditions_hash = Hash[assessments.joins(:reported_condition).pluck('conditions.id', :assessment_id).map { |id, assessment_id| [id, assessment_id] }]
                        .transform_values { |assessment_id| { assessment_id: assessment_id, symptoms: {} } }

      # Uses index_symptoms_on_condition_id
      all_symptoms = Symptom.where(condition_id: conditions_hash.keys)
      all_symptoms.where(type: 'BoolSymptom').pluck(:condition_id, :name, :bool_value).each do |(condition_id, name, bool_value)|
        conditions_hash[condition_id][:symptoms][name] = bool_value
      end
      all_symptoms.where(type: 'IntegerSymptom').pluck(:condition_id, :name, :bool_value).each do |(condition_id, name, int_value)|
        conditions_hash[condition_id][:symptoms][name] = int_value
      end
      all_symptoms.where(type: 'FloatSymptom').pluck(:condition_id, :name, :bool_value).each do |(condition_id, name, float_value)|
        conditions_hash[condition_id][:symptoms][name] = float_value
      end
      assessments_hash = Hash[conditions_hash.map { |_, condition| [condition[:assessment_id], condition[:symptoms]] }]
    end

    assessments_details = []
    assessments.each do |assessment|
      assessment_details = assessment.custom_details(fields, patients_identifiers[assessment.patient_id]) || {}
      if fields.include?(:symptoms)
        # Using Symptom.all for finding distinct symptom names is actually faster here because it can use symptoms_index_chain_1
        Symptom.all.distinct.pluck(:name).each do |symptom_name|
          # Nil check in case for some reason there were assessments with nil ReportedCondition
          next if assessments_hash[assessment[:id]].nil?

          assessment_details[symptom_name.to_sym] = assessments_hash[assessment[:id]][symptom_name]
        end
      end
      assessments_details << assessment_details
    end
    assessments_details
  end

  # Extracts laboratory data values given relevant fields
  def extract_laboratories_details(patients_identifiers, laboratories, fields)
    laboratories.map { |laboratory| laboratory.custom_details(fields, patients_identifiers[laboratory.patient_id]) }
  end

  # Extracts close contact data values given relevant fields
  def extract_close_contacts_details(patients_identifiers, close_contacts, fields)
    close_contacts.map { |close_contact| close_contact.custom_details(fields, patients_identifiers[close_contact.patient_id]) }
  end

  # Extracts transfer data values given relevant fields
  def extract_transfers_details(patients_identifiers, transfers, fields)
    selected_fields = fields & %i[id patient_id created_at updated_at]
    plucked_fields = selected_fields.dup

    if fields.include?(:who)
      transfers = transfers.joins('INNER JOIN users ON transfers.who_id = users.id')
      selected_fields << 'users.email AS who'
      plucked_fields << :who
    end

    if fields.include?(:from_jurisdiction)
      transfers = transfers.joins('INNER JOIN jurisdictions from_jurs ON transfers.from_jurisdiction_id = from_jurs.id')
      selected_fields << 'from_jurs.path AS from_jurisdiction'
      plucked_fields << :from_jurisdiction
    end

    if fields.include?(:to_jurisdiction)
      transfers = transfers.joins('INNER JOIN jurisdictions to_jurs ON transfers.to_jurisdiction_id = to_jurs.id')
      selected_fields << 'to_jurs.path AS to_jurisdiction'
      plucked_fields << :to_jurisdiction
    end

    transfers.pluck(*selected_fields).map do |t|
      transfer = plucked_fields.zip(t).to_h
      (PATIENT_ALTERNATIVE_IDENTIFIERS & fields).each { |identifier| transfer[identifier] = patients_identifiers[transfer[:patient_id]][identifier] }
      transfer
    end
  end

  # Extracts history data values given relevant fields
  def extract_histories_details(patients_identifiers, histories, fields)
    histories.map { |history| history.custom_details(fields, patients_identifiers[history.patient_id]) }
  end
end
