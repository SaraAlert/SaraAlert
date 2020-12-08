# frozen_string_literal: true

# Helper methods for the import and export controllers
module ImportExport # rubocop:todo Metrics/ModuleLength
  include ValidationHelper
  include ImportExportConstants

  def unformat_enum_field(value)
    value.to_s.downcase.gsub(/[ -.]/, '')
  end

  def extract_patients_details(patients_group, fields)
    # perform the following queries in bulk only if requested for better performance
    patients_jurisdiction_names = jurisdiction_names(patients_group) if fields.include?(:jurisdiction_name)
    patients_jurisdiction_paths = jurisdiction_paths(patients_group) if fields.include?(:jurisdiction_path)
    patients_transfers = transfers(patients_group) if (fields & %i[transferred_from transferred_to]).any?
    lab_fields = %i[lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report lab_2_result]
    patients_labs = laboratories(patients_group) if (fields & lab_fields).any?
    patients_creators = Hash[User.find(patients_group.pluck(:creator_id)).pluck(:id, :email)] if fields.include?(:creator)

    # construct patient details
    patients_details = []
    patients_group.each do |patient|
      # populate requested inherent fields
      patient_details = extract_incomplete_patient_details(patient, fields)

      # populate creator if requested
      patient_details[:creator] = patients_creators[patient.creator_id] || '' if fields.include?(:creator)

      # populate jurisdiction if requested
      patient_details[:jurisdiction_name] = patients_jurisdiction_names[patient.id] || '' if fields.include?(:jurisdiction_name)
      patient_details[:jurisdiction_path] = patients_jurisdiction_paths[patient.id] || '' if fields.include?(:jurisdiction_path)

      # populate latest transfer from and to if requested
      if patients_transfers&.key?(patient.id)
        patient_details[:transferred_from] = patients_transfers[patient.id][:trasnferred_from] if fields.include?(:transferred_from)
        patient_details[:transferred_to] = patients_transfers[patient.id][:transferred_to] if fields.include?(:transferred_to)
      end

      # populate labs if requested
      if patients_labs&.key?(patient.id)
        if patients_labs[patient.id].key?(:first)
          patient_details[:lab_1_type] = patients_labs[patient.id][:first][:lab_type] || '' if fields.include?(:lab_1_type)
          if fields.include?(:lab_1_specimen_collection)
            patient_details[:lab_1_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_1_report] = patients_labs[patient.id][:first][:report]&.strftime('%F') || '' if fields.include?(:lab_1_report)
          patient_details[:lab_1_result] = patients_labs[patient.id][:first][:result] || '' if fields.include?(:lab_1_result)
        end
        if patients_labs[patient.id].key?(:second)
          patient_details[:lab_2_type] = patients_labs[patient.id][:first][:lab_type] || '' if fields.include?(:lab_2_type)
          if fields.include?(:lab_2_specimen_collection)
            patient_details[:lab_2_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_2_report] = patients_labs[patient.id][:first][:report]&.strftime('%F') || '' if fields.include?(:lab_2_report)
          patient_details[:lab_2_result] = patients_labs[patient.id][:first][:result] || '' if fields.include?(:lab_2_result)
        end
      end

      patients_details << patient_details
    end

    patients_details
  end

  def extract_incomplete_patient_details(patient, fields)
    patient_details = {}

    (PATIENT_FIELD_TYPES[:numbers] + PATIENT_FIELD_TYPES[:strings]).each do |field|
      patient_details[field] = patient[field] || '' if fields.include?(field)
    end

    PATIENT_FIELD_TYPES[:dates].each do |field|
      patient_details[field] = patient[field]&.strftime('%F') || '' if fields.include?(field)
    end

    PATIENT_FIELD_TYPES[:booleans].each do |field|
      patient_details[field] = patient[field] || false if fields.include?(field)
    end

    PATIENT_FIELD_TYPES[:phones].each do |field|
      patient_details[field] = format_phone_number(patient[field]) if fields.include?(field)
    end

    RACE_FIELDS.each { |race| patient_details[race] = patient[race] || false } if fields.include?(:race)

    patient_details[:name] = patient.displayed_name if fields.include?(:name)
    patient_details[:age] = patient.calc_current_age if fields.include?(:age)
    patient_details[:workflow] = patient[:isolation] ? 'Isolation' : 'Workflow'
    patient_details[:symptom_onset_defined_by] = patient[:user_defined_symptom_onset] ? 'User' : 'System'
    patient_details[:monitoring_status] = patient[:monitoring] ? 'Actively Monitoring' : 'Not Monitoring'
    patient_details[:end_of_monitoring] = patient.end_of_monitoring || '' if fields.include?(:end_of_monitoring)
    patient_details[:expected_purge_date] = patient.expected_purge_date || '' if fields.include?(:expected_purge_date)
    patient_details[:status] = PATIENT_STATUS_LABELS[patient.status] || '' if fields.include?(:status)

    patient_details
  end

  # def csv_line_list(patients)
  #   package = CSV.generate(headers: true) do |csv|
  #     csv << LINELIST_HEADERS
  #     patient_statuses = statuses(patients)
  #     patients.find_in_batches(batch_size: 500) do |patients_group|
  #       linelists = linelists_for_export(patients_group, patient_statuses)
  #       patients_group.each do |patient|
  #         csv << linelists[patient.id].values
  #       end
  #     end
  #   end
  #   Base64.encode64(package)
  # end

  # def sara_alert_format(patients)
  #   Axlsx::Package.new do |p|
  #     p.workbook.add_worksheet(name: 'Monitorees') do |sheet|
  #       sheet.add_row COMPREHENSIVE_HEADERS
  #       patient_statuses = statuses(patients)
  #       patients.find_in_batches(batch_size: 500) do |patients_group|
  #         comprehensive_details = comprehensive_details_for_export(patients_group, patient_statuses)
  #         patients_group.each do |patient|
  #           sheet.add_row comprehensive_details[patient.id].values, { types: Array.new(COMPREHENSIVE_HEADERS.length, :string) }
  #         end
  #       end
  #     end
  #     return Base64.encode64(p.to_stream.read)
  #   end
  # end

  # def excel_export(patients)
  #   Axlsx::Package.new do |p|
  #     p.workbook.add_worksheet(name: 'Monitorees List') do |sheet|
  #       headers = MONITOREES_LIST_HEADERS
  #       sheet.add_row headers
  #       patient_statuses = statuses(patients)
  #       patients.find_in_batches(batch_size: 500) do |patients_group|
  #         comprehensive_details = comprehensive_details_for_export(patients_group, patient_statuses)
  #         patients_group.each do |patient|
  #           extended_isolation = patient[:extended_isolation]&.strftime('%F') || ''
  #           values = [patient.id] + comprehensive_details[patient.id].values + [extended_isolation]
  #           sheet.add_row values, { types: Array.new(MONITOREES_LIST_HEADERS.length + 2, :string) }
  #         end
  #       end
  #     end
  #     p.workbook.add_worksheet(name: 'Reports') do |sheet|
  #       # headers and all unique symptoms
  #       symptom_labels = patients.joins(assessments: [{ reported_condition: :symptoms }]).select('symptoms.label').distinct.pluck('symptoms.label').sort
  #       sheet.add_row ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels.to_a.sort

  #       # assessments sorted by patients
  #       patients.find_in_batches(batch_size: 500) do |patients_group|
  #         assessments = Assessment.where(patient_id: patients_group.pluck(:id))
  #         conditions = ReportedCondition.where(assessment_id: assessments.pluck(:id))
  #         symptoms = Symptom.where(condition_id: conditions.pluck(:id))

  #         # construct hash containing symptoms by assessment_id
  #         conditions_hash = Hash[conditions.pluck(:id, :assessment_id).map { |id, assessment_id| [id, assessment_id] }]
  #                           .transform_values { |assessment_id| { assessment_id: assessment_id, symptoms: {} } }
  #         symptoms.each do |symptom|
  #           conditions_hash[symptom[:condition_id]][:symptoms][symptom[:label]] = symptom.value
  #         end
  #         assessments_hash = Hash[conditions_hash.map { |_, condition| [condition[:assessment_id], condition[:symptoms]] }]

  #         # combine symptoms with assessment summary
  #         assessment_summary_arrays = assessments.order(:patient_id, :id).pluck(:id, :patient_id, :symptomatic, :who_reported, :created_at, :updated_at)
  #         assessment_summary_arrays.each do |assessment_summary_array|
  #           symptoms_hash = assessments_hash[assessment_summary_array[0]]
  #           next if symptoms_hash.nil?

  #           symptoms_array = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s }
  #           row = assessment_summary_array[1..].concat(symptoms_array)
  #           sheet.add_row row, { types: Array.new(row.length, :string) }
  #         end
  #       end
  #     end
  #     p.workbook.add_worksheet(name: 'Lab Results') do |sheet|
  #       labs = Laboratory.where(patient_id: patients.pluck(:id))
  #       lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
  #       sheet.add_row lab_headers
  #       labs.find_each(batch_size: 500) do |lab|
  #         sheet.add_row lab.details.values, { types: Array.new(lab_headers.length, :string) }
  #       end
  #     end
  #     p.workbook.add_worksheet(name: 'Edit Histories') do |sheet|
  #       histories = History.where(patient_id: patients.pluck(:id))
  #       history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
  #       sheet.add_row history_headers
  #       histories.find_each(batch_size: 500) do |history|
  #         sheet.add_row history.details.values, { types: Array.new(history_headers.length, :string) }
  #       end
  #     end
  #     return Base64.encode64(p.to_stream.read)
  #   end
  # end

  # def excel_export_monitorees(patients)
  #   Axlsx::Package.new do |p|
  #     p.workbook.add_worksheet(name: 'Monitorees List') do |sheet|
  #       headers = MONITOREES_LIST_HEADERS
  #       sheet.add_row headers
  #       patient_statuses = statuses(patients)
  #       patients.find_in_batches(batch_size: 500) do |patients_group|
  #         comprehensive_details = comprehensive_details_for_export(patients_group, patient_statuses)
  #         patients_group.each do |patient|
  #           extended_isolation = patient[:extended_isolation]&.strftime('%F') || ''
  #           values = [patient.id] + comprehensive_details[patient.id].values + [extended_isolation]
  #           sheet.add_row values, { types: Array.new(MONITOREES_LIST_HEADERS.length + 2, :string) }
  #         end
  #       end
  #     end
  #     return Base64.encode64(p.to_stream.read)
  #   end
  # end

  # def excel_export_assessments(patients)
  #   Axlsx::Package.new do |p|
  #     p.workbook.add_worksheet(name: 'Reports') do |sheet|
  #       # headers and all unique symptoms
  #       symptom_labels = patients.joins(assessments: [{ reported_condition: :symptoms }]).select('symptoms.label').distinct.pluck('symptoms.label').sort
  #       sheet.add_row ['Patient ID', 'Symptomatic', 'Who Reported', 'Created At', 'Updated At'] + symptom_labels.to_a.sort

  #       # assessments sorted by patients
  #       patients.find_in_batches(batch_size: 500) do |patients_group|
  #         assessments = Assessment.where(patient_id: patients_group.pluck(:id))
  #         conditions = ReportedCondition.where(assessment_id: assessments.pluck(:id))
  #         symptoms = Symptom.where(condition_id: conditions.pluck(:id))

  #         # construct hash containing symptoms by assessment_id
  #         conditions_hash = Hash[conditions.pluck(:id, :assessment_id).map { |id, assessment_id| [id, assessment_id] }]
  #                           .transform_values { |assessment_id| { assessment_id: assessment_id, symptoms: {} } }
  #         symptoms.each do |symptom|
  #           conditions_hash[symptom[:condition_id]][:symptoms][symptom[:label]] = symptom.value
  #         end
  #         assessments_hash = Hash[conditions_hash.map { |_, condition| [condition[:assessment_id], condition[:symptoms]] }]

  #         # combine symptoms with assessment summary
  #         assessment_summary_arrays = assessments.order(:patient_id, :id).pluck(:id, :patient_id, :symptomatic, :who_reported, :created_at, :updated_at)
  #         assessment_summary_arrays.each do |assessment_summary_array|
  #           symptoms_hash = assessments_hash[assessment_summary_array[0]]
  #           next if symptoms_hash.nil?

  #           symptoms_array = symptom_labels.map { |symptom_label| symptoms_hash[symptom_label].to_s }
  #           row = assessment_summary_array[1..].concat(symptoms_array)
  #           sheet.add_row row, { types: Array.new(row.length, :string) }
  #         end
  #       end
  #     end
  #     return Base64.encode64(p.to_stream.read)
  #   end
  # end

  # def excel_export_lab_results(patients)
  #   Axlsx::Package.new do |p|
  #     p.workbook.add_worksheet(name: 'Lab Results') do |sheet|
  #       labs = Laboratory.where(patient_id: patients.pluck(:id))
  #       lab_headers = ['Patient ID', 'Lab Type', 'Specimen Collection Date', 'Report Date', 'Result Date', 'Created At', 'Updated At']
  #       sheet.add_row lab_headers
  #       labs.find_each(batch_size: 500) do |lab|
  #         sheet.add_row lab.details.values, { types: Array.new(lab_headers.length, :string) }
  #       end
  #     end
  #     return Base64.encode64(p.to_stream.read)
  #   end
  # end

  # def excel_export_histories(patients)
  #   Axlsx::Package.new do |p|
  #     p.workbook.add_worksheet(name: 'Edit Histories') do |sheet|
  #       histories = History.where(patient_id: patients.pluck(:id))
  #       history_headers = ['Patient ID', 'Comment', 'Created By', 'History Type', 'Created At', 'Updated At']
  #       sheet.add_row history_headers
  #       histories.find_each(batch_size: 500) do |history|
  #         sheet.add_row history.details.values, { types: Array.new(history_headers.length, :string) }
  #       end
  #     end
  #     return Base64.encode64(p.to_stream.read)
  #   end
  # end

  # Patient fields relevant to linelist export
  def linelists_for_export(patients, patient_statuses)
    linelists = incomplete_linelists_for_export(patients)
    patients_jurisdiction_names = jurisdiction_names(patients)
    patients_transfers = transfers(patients)
    patients.each do |patient|
      linelists[patient.id][:jurisdiction] = patients_jurisdiction_names[patient.id]
      linelists[patient.id][:status] = patient_statuses[patient.id]&.gsub('exposure ', '')&.gsub('isolation ', '')
      next unless patients_transfers[patient.id]

      %i[transferred_at transferred_from transferred_to].each do |transfer_field|
        linelists[patient.id][transfer_field] = patients_transfers[patient.id][transfer_field]
      end
    end
    linelists
  end

  # Patient fields relevant to sara alert format and excel export
  def comprehensive_details_for_export(patients, patient_statuses)
    comprehensive_details = incomplete_comprehensive_details_for_export(patients)
    patients_jurisdiction_paths = jurisdiction_paths(patients)
    patients_labs = laboratories(patients)
    patients.each do |patient|
      comprehensive_details[patient.id][:jurisdiction_path] = patients_jurisdiction_paths[patient.id]
      comprehensive_details[patient.id][:status] = patient_statuses[patient.id]
      next unless patients_labs.key?(patient.id)
      next unless patients_labs[patient.id].key?(:first)

      comprehensive_details[patient.id][:lab_1_type] = patients_labs[patient.id][:first][:lab_type]
      comprehensive_details[patient.id][:lab_1_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F')
      comprehensive_details[patient.id][:lab_1_report] = patients_labs[patient.id][:first][:report]&.strftime('%F')
      comprehensive_details[patient.id][:lab_1_result] = patients_labs[patient.id][:first][:result]
      next unless patients_labs[patient.id].key?(:second)

      comprehensive_details[patient.id][:lab_2_type] = patients_labs[patient.id][:second][:lab_type]
      comprehensive_details[patient.id][:lab_2_specimen_collection] = patients_labs[patient.id][:second][:specimen_collection]&.strftime('%F')
      comprehensive_details[patient.id][:lab_2_report] = patients_labs[patient.id][:second][:report]&.strftime('%F')
      comprehensive_details[patient.id][:lab_2_result] = patients_labs[patient.id][:second][:result]
    end
    comprehensive_details
  end

  # Status of each patient (faster to do this in bulk than individually for exports)
  def statuses(patients)
    tabs = {
      closed: patients.monitoring_closed.pluck(:id),
      purged: patients.purged.pluck(:id),
      exposure_symptomatic: patients.exposure_symptomatic.pluck(:id),
      exposure_non_reporting: patients.exposure_non_reporting.pluck(:id),
      exposure_asymptomatic: patients.exposure_asymptomatic.pluck(:id),
      exposure_under_investigation: patients.exposure_under_investigation.pluck(:id),
      isolation_asymp_non_test_based: patients.isolation_asymp_non_test_based.pluck(:id),
      isolation_symp_non_test_based: patients.isolation_symp_non_test_based.pluck(:id),
      isolation_test_based: patients.isolation_test_based.pluck(:id),
      isolation_non_reporting: patients.isolation_non_reporting.pluck(:id),
      isolation_reporting: patients.isolation_reporting.pluck(:id)
    }
    patient_statuses = {}
    tabs.each do |tab, patient_ids|
      patient_ids.each do |patient_id|
        patient_statuses[patient_id] = tab&.to_s&.humanize&.downcase
      end
    end
    patient_statuses
  end

  # Latest transfer of each patient
  def transfers(patients)
    transfers = patients.pluck(:id, :latest_transfer_at)
    transfers = Transfer.where(patient_id: transfers.map { |lt| lt[0] }, created_at: transfers.map { |lt| lt[1] })
    jurisdictions = Jurisdiction.find(transfers.pluck(:from_jurisdiction_id, :to_jurisdiction_id).flatten.uniq)
    jurisdiction_paths = Hash[jurisdictions.pluck(:id, :path).map { |id, path| [id, path] }]
    Hash[transfers.pluck(:patient_id, :created_at, :from_jurisdiction_id, :to_jurisdiction_id)
                  .map do |patient_id, created_at, from_jurisdiction_id, to_jurisdiction_id|
                    [patient_id, {
                      transferred_at: created_at.rfc2822,
                      transferred_from: jurisdiction_paths[from_jurisdiction_id],
                      transferred_to: jurisdiction_paths[to_jurisdiction_id]
                    }]
                  end
        ]
  end

  # 2 Latest laboratories of each patient
  def laboratories(patients)
    latest_labs = Hash[patients.pluck(:id).map { |id| [id, {}] }]
    Laboratory.where(patient_id: patients.pluck(:id)).order(report: :desc).each do |lab|
      if !latest_labs[lab.patient_id].key?(:first)
        latest_labs[lab.patient_id][:first] = {
          lab_type: lab[:lab_type],
          specimen_collection: lab[:specimen_collection],
          report: lab[:report],
          result: lab[:result]
        }
      elsif !latest_labs[lab.patient_id].key?(:second)
        latest_labs[lab.patient_id][:second] = {
          lab_type: lab[:lab_type],
          specimen_collection: lab[:specimen_collection],
          report: lab[:report],
          result: lab[:result]
        }
      end
    end
    latest_labs
  end

  # Hash containing mappings between jurisdiction id and path for each patient
  def jurisdiction_paths(patients)
    jurisdiction_paths = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :path).map { |id, path| [id, path] }]
    patients_jurisdiction_paths = {}
    patients.each do |patient|
      patients_jurisdiction_paths[patient.id] = jurisdiction_paths[patient.jurisdiction_id]
    end
    patients_jurisdiction_paths
  end

  # Hash containing mappings between jurisdiction id and name for each patient
  def jurisdiction_names(patients)
    jurisdiction_names = Hash[Jurisdiction.find(patients.pluck(:jurisdiction_id).uniq).pluck(:id, :name).map { |id, name| [id, name] }]
    patients_jurisdiction_names = {}
    patients.each do |patient|
      patients_jurisdiction_names[patient.id] = jurisdiction_names[patient.jurisdiction_id]
    end
    patients_jurisdiction_names
  end

  # Converts phone number from e164 to CDC recommended format
  def format_phone_number(phone)
    cleaned_phone_number = Phonelib.parse(phone).national(false)
    return nil if cleaned_phone_number.nil? || cleaned_phone_number.length != 10

    cleaned_phone_number.insert(6, '-').insert(3, '-')
  end

  # Linelist fields obtainable without any joins
  def incomplete_linelists_for_export(patients)
    linelists = {}
    patients.each do |patient|
      linelists[patient.id] = {
        id: patient[:id],
        name: "#{patient[:last_name]}#{patient[:first_name].blank? ? '' : ', ' + patient[:first_name]}",
        jurisdiction: '',
        assigned_user: patient[:assigned_user] || '',
        state_local_id: patient[:user_defined_id_statelocal] || '',
        sex: patient[:sex] || '',
        dob: patient[:date_of_birth]&.strftime('%F') || '',
        end_of_monitoring: patient.end_of_monitoring,
        risk_level: patient[:exposure_risk_assessment] || '',
        monitoring_plan: patient[:monitoring_plan] || '',
        latest_report: patient[:latest_assessment_at]&.rfc2822,
        transferred_at: '',
        reason_for_closure: patient[:monitoring_reason] || '',
        public_health_action: patient[:public_health_action] || '',
        status: '',
        closed_at: patient[:closed_at]&.rfc2822 || '',
        transferred_from: '',
        transferred_to: '',
        expected_purge_date: patient[:updated_at].nil? ? '' : ((patient[:updated_at] + ADMIN_OPTIONS['purgeable_after'].minutes)&.rfc2822 || ''),
        symptom_onset: patient[:symptom_onset]&.strftime('%F') || '',
        extended_isolation: patient[:extended_isolation]&.strftime('%F') || ''
      }
    end
    linelists
  end

  # Comprehensive details fields obtainable without any joins
  def incomplete_comprehensive_details_for_export(patients)
    comprehensive_details = {}
    patients.each do |patient|
      comprehensive_details[patient.id] = {
        first_name: patient[:first_name] || '',
        middle_name: patient[:middle_name] || '',
        last_name: patient[:last_name] || '',
        date_of_birth: patient[:date_of_birth]&.strftime('%F') || '',
        sex: patient[:sex] || '',
        white: patient[:white] || false,
        black_or_african_american: patient[:black_or_african_american] || false,
        american_indian_or_alaska_native: patient[:american_indian_or_alaska_native] || false,
        asian: patient[:asian] || false,
        native_hawaiian_or_other_pacific_islander: patient[:native_hawaiian_or_other_pacific_islander] || false,
        ethnicity: patient[:ethnicity] || '',
        primary_language: patient[:primary_language] || '',
        secondary_language: patient[:secondary_language] || '',
        interpretation_required: patient[:interpretation_required] || false,
        nationality: patient[:nationality] || '',
        user_defined_id_statelocal: patient[:user_defined_id_statelocal] || '',
        user_defined_id_cdc: patient[:user_defined_id_cdc] || '',
        user_defined_id_nndss: patient[:user_defined_id_nndss] || '',
        address_line_1: patient[:address_line_1] || '',
        address_city: patient[:address_city] || '',
        address_state: patient[:address_state] || '',
        address_line_2: patient[:address_line_2] || '',
        address_zip: patient[:address_zip] || '',
        address_county: patient[:address_county] || '',
        foreign_address_line_1: patient[:foreign_address_line_1] || '',
        foreign_address_city: patient[:foreign_address_city] || '',
        foreign_address_country: patient[:foreign_address_country] || '',
        foreign_address_line_2: patient[:foreign_address_line_2] || '',
        foreign_address_zip: patient[:foreign_address_zip] || '',
        foreign_address_line_3: patient[:foreign_address_line_3] || '',
        foreign_address_state: patient[:foreign_address_state] || '',
        monitored_address_line_1: patient[:monitored_address_line_1] || '',
        monitored_address_city: patient[:monitored_address_city] || '',
        monitored_address_state: patient[:monitored_address_state] || '',
        monitored_address_line_2: patient[:monitored_address_line_2] || '',
        monitored_address_zip: patient[:monitored_address_zip] || '',
        monitored_address_county: patient[:monitored_address_county] || '',
        foreign_monitored_address_line_1: patient[:foreign_monitored_address_line_1] || '',
        foreign_monitored_address_city: patient[:foreign_monitored_address_city] || '',
        foreign_monitored_address_state: patient[:foreign_monitored_address_state] || '',
        foreign_monitored_address_line_2: patient[:foreign_monitored_address_line_2] || '',
        foreign_monitored_address_zip: patient[:foreign_monitored_address_zip] || '',
        foreign_monitored_address_county: patient[:foreign_monitored_address_county] || '',
        preferred_contact_method: patient[:preferred_contact_method] || '',
        primary_telephone: patient[:primary_telephone] ? format_phone_number(patient[:primary_telephone]) : '',
        primary_telephone_type: patient[:primary_telephone_type] || '',
        secondary_telephone: patient[:secondary_telephone] ? format_phone_number(patient[:secondary_telephone]) : '',
        secondary_telephone_type: patient[:secondary_telephone_type] || '',
        preferred_contact_time: patient[:preferred_contact_time] || '',
        email: patient[:email] || '',
        port_of_origin: patient[:port_of_origin] || '',
        date_of_departure: patient[:date_of_departure]&.strftime('%F') || '',
        source_of_report: patient[:source_of_report] || '',
        flight_or_vessel_number: patient[:flight_or_vessel_number] || '',
        flight_or_vessel_carrier: patient[:flight_or_vessel_carrier] || '',
        port_of_entry_into_usa: patient[:port_of_entry_into_usa] || '',
        date_of_arrival: patient[:date_of_arrival]&.strftime('%F') || '',
        travel_related_notes: patient[:travel_related_notes] || '',
        additional_planned_travel_type: patient[:additional_planned_travel_type] || '',
        additional_planned_travel_destination: patient[:additional_planned_travel_destination] || '',
        additional_planned_travel_destination_state: patient[:additional_planned_travel_destination_state] || '',
        additional_planned_travel_destination_country: patient[:additional_planned_travel_destination_country] || '',
        additional_planned_travel_port_of_departure: patient[:additional_planned_travel_port_of_departure] || '',
        additional_planned_travel_start_date: patient[:additional_planned_travel_start_date]&.strftime('%F') || '',
        additional_planned_travel_end_date: patient[:additional_planned_travel_end_date]&.strftime('%F') || '',
        additional_planned_travel_related_notes: patient[:additional_planned_travel_related_notes] || '',
        last_date_of_exposure: patient[:last_date_of_exposure]&.strftime('%F') || '',
        potential_exposure_location: patient[:potential_exposure_location] || '',
        potential_exposure_country: patient[:potential_exposure_country] || '',
        contact_of_known_case: patient[:contact_of_known_case] || '',
        contact_of_known_case_id: patient[:contact_of_known_case_id] || '',
        travel_to_affected_country_or_area: patient[:travel_to_affected_country_or_area] || false,
        was_in_health_care_facility_with_known_cases: patient[:was_in_health_care_facility_with_known_cases] || false,
        was_in_health_care_facility_with_known_cases_facility_name: patient[:was_in_health_care_facility_with_known_cases_facility_name] || '',
        laboratory_personnel: patient[:laboratory_personnel] || false,
        laboratory_personnel_facility_name: patient[:laboratory_personnel_facility_name] || '',
        healthcare_personnel: patient[:healthcare_personnel] || false,
        healthcare_personnel_facility_name: patient[:healthcare_personnel_facility_name] || '',
        crew_on_passenger_or_cargo_flight: patient[:crew_on_passenger_or_cargo_flight] || false,
        member_of_a_common_exposure_cohort: patient[:member_of_a_common_exposure_cohort] || false,
        member_of_a_common_exposure_cohort_type: patient[:member_of_a_common_exposure_cohort_type] || '',
        exposure_risk_assessment: patient[:exposure_risk_assessment] || '',
        monitoring_plan: patient[:monitoring_plan] || '',
        exposure_notes: patient[:exposure_notes] || '',
        status: '',
        symptom_onset: patient[:symptom_onset]&.strftime('%F') || '',
        case_status: patient[:case_status] || '',
        lab_1_type: '',
        lab_1_specimen_collection: '',
        lab_1_report: '',
        lab_1_result: '',
        lab_2_type: '',
        lab_2_specimen_collection: '',
        lab_2_report: '',
        lab_2_result: '',
        jurisdiction_path: '',
        assigned_user: patient[:assigned_user] || '',
        gender_identity: patient[:gender_identity] || '',
        sexual_orientation: patient[:sexual_orientation] || ''
      }
    end
    comprehensive_details
  end
end
