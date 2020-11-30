# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :exports
  include ImportExport
  include PatientQueryHelper

  # Limits number of records to be considered for a single exported file to handle maximum file size limit.
  # Adds additional files as needed if records exceeds batch size.
  RECORD_BATCH_SIZE = 10_000

  def perform(user_id, export_type, config)
    user = User.find_by(id: user_id)
    return if user.nil?

    # Delete any existing downloads of this type
    user.downloads.where(export_type: export_type).delete_all

    # Construct export
    lookups = []
    patients = patients_by_query(user, config[:data][:patients][:query])
    patients&.in_batches(of: RECORD_BATCH_SIZE)&.each_with_index do |patients_group, index|
      exported_patients = extract_patients_details_in_batch(patients_group, config[:data][:patients][:checked].map(&:to_sym))
      lookups << create_lookup(user_id, export_type, config, :patients, exported_patients, index)

      patient_ids = patients_group.pluck(:id)

      if config[:data][:assessments][:checked].present?
        assessments = assessments_by_query(patient_ids, config[:data][:assessments][:query])
        exported_assessments, symptom_names = extract_assessments_details_in_batch(assessments, config[:data][:assessments][:checked].map(&:to_sym),
                                                                                   config[:data][:assessments][:query])
        if config[:data][:assessments][:checked].include?(:symptoms.to_s)
          config[:data][:assessments][:checked].delete(:symptoms.to_s)
          config[:data][:assessments][:checked].concat(symptom_names)
        end
        lookups << create_lookup(user_id, export_type, config, :assessments, exported_assessments, index)
      end

      if config[:data][:laboratories][:checked].present?
        laboratories = laboratories_by_query(patient_ids, config[:data][:laboratories][:query])
        exported_laboratories = extract_laboratories_details_in_batch(laboratories, config[:data][:laboratories][:checked].map(&:to_sym))
        lookups << create_lookup(user_id, export_type, config, :laboratories, exported_laboratories, index)
      end

      if config[:data][:close_contacts][:checked].present?
        close_contacts = close_contacts_by_query(patient_ids, config[:data][:close_contacts][:query])
        exported_close_contacts = extract_close_contacts_details_in_batch(close_contacts, config[:data][:close_contacts][:checked].map(&:to_sym))
        lookups << create_lookup(user_id, export_type, config, :close_contacts, exported_close_contacts, index)
      end

      if config[:data][:transfers][:checked].present?
        transfers = transfers_by_query(patient_ids, config[:data][:transfers][:query])
        exported_transfers = extract_transfers_details_in_batch(transfers, config[:data][:transfers][:checked].map(&:to_sym))
        lookups << create_lookup(user_id, export_type, config, :transfers, exported_transfers, index)
      end

      if config[:data][:histories][:checked].present?
        histories = histories_by_query(patient_ids, config[:data][:histories][:query])
        exported_histories = extract_histories_details_in_batch(histories, config[:data][:histories][:checked].map(&:to_sym))
        lookups << create_lookup(user_id, export_type, config, :histories, exported_histories, index)
      end
    end

    return if lookups.empty?

    # Sort lookups by filename so that they are grouped together accordingly after batching
    lookups = lookups.sort_by { |lookup| lookup[:filename] }

    # Send an email to user
    UserMailer.download_email(user, export_type, lookups, RECORD_BATCH_SIZE).deliver_later
  end

  # rubocop:disable Lint/UnusedMethodArgument
  def assessments_by_query(patient_ids, query)
    Assessment.where(patient_id: patient_ids).order(:patient_id)
  end

  def laboratories_by_query(patient_ids, query)
    Laboratory.where(patient_id: patient_ids).order(:patient_id)
  end

  def close_contacts_by_query(patient_ids, query)
    CloseContact.where(patient_id: patient_ids).order(:patient_id)
  end

  def transfers_by_query(patient_ids, query)
    Transfer.where(patient_id: patient_ids).order(:patient_id)
  end

  def histories_by_query(patient_ids, query)
    History.where(patient_id: patient_ids).order(:patient_id)
  end
  # rubocop:enable Lint/UnusedMethodArgument

  # rubocop:disable Metrics/ParameterLists
  def create_lookup(user_id, export_type, config, data_type, records, index)
    fields = config[:data][data_type][:checked].map(&:to_sym)
    filename = build_filename("#{export_type}-#{CUSTOM_EXPORT_OPTIONS[data_type][:label].gsub(' ', '-')}", index + 1, config[:format])
    case config[:format]
    when 'csv'
      get_file(user_id, csv_export(data_type, fields, records), filename, export_type)
    when 'xlsx'
      get_file(user_id, xlsx_export(data_type, fields, records), filename, export_type)
    end
  end
  # rubocop:enable Metrics/ParameterLists

  def csv_export(data_type, fields, records)
    package = CSV.generate(headers: true) do |csv|
      csv << fields.map { |field| ALL_FIELDS_NAMES[data_type][field] }
      records.each do |record|
        csv << fields.map { |field| record[field] }
      end
    end
    Base64.encode64(package)
  end

  def xlsx_export(data_type, fields, records)
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: CUSTOM_EXPORT_OPTIONS[data_type][:label]) do |sheet|
        sheet.add_row(fields.map { |field| ALL_FIELDS_NAMES[data_type][field] })
        records.each do |record|
          sheet.add_row(fields.map { |field| record[field] }, { types: Array.new(fields.length, :string) })
        end
      end
      return Base64.encode64(p.to_stream.read)
    end
  end

  # Builds a file name using the base name, index, date, and extension.
  # Ex: "Sara-Alert-Linelist-Isolation-2020-09-01T14:15:05-04:00-1"
  def build_filename(base_name, file_index, file_extension)
    "#{base_name}-#{DateTime.now}-#{file_index}.#{file_extension}"
  end

  # Gets a single download with the provided filename information and containing the provided data.
  def get_file(user_id, data, full_filename, export_type)
    { lookup: save_download(user_id, data, full_filename, export_type), filename: full_filename }
  end

  # Save a download file and return the lookup
  def save_download(user_id, data, filename, export_type)
    lookup = SecureRandom.uuid
    if ActiveRecord::Base.logger.formatter.nil?
      download = Download.insert(user_id: user_id, contents: data, filename: filename, lookup: lookup,
                                 export_type: export_type, created_at: DateTime.now, updated_at: DateTime.now)
    else
      ActiveRecord::Base.logger.silence do
        download = Download.insert(user_id: user_id, contents: data, filename: filename, lookup: lookup,
                                   export_type: export_type, created_at: DateTime.now, updated_at: DateTime.now)
      end
    end
    lookup
  end

  # def perform(user_id, export_type)
  #   user = User.find_by(id: user_id)
  #   return if user.nil?

  #   # Delete any existing downloads of this type
  #   user.downloads.where(export_type: export_type).delete_all

  #   # Construct export
  #   lookups = []
  #   case export_type
  #   when 'csv_exposure'
  #     patients = user.viewable_patients.where(isolation: false).where(purged: false)
  #     base_filename = 'Sara-Alert-Linelist-Exposure'
  #     file_extension = 'csv'
  #     patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
  #       data = csv_line_list(group)
  #       lookups << get_file(user_id, data, build_filename(base_filename, index + 1, file_extension), export_type)
  #     end
  #   when 'csv_isolation'
  #     patients = user.viewable_patients.where(isolation: true).where(purged: false)
  #     base_filename = 'Sara-Alert-Linelist-Isolation'
  #     file_extension = 'csv'
  #     patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
  #       data = csv_line_list(group)
  #       lookups << get_file(user_id, data, build_filename(base_filename, index + 1, file_extension), export_type)
  #     end
  #   when 'sara_format_exposure'
  #     patients = user.viewable_patients.where(isolation: false).where(purged: false)
  #     base_filename = 'Sara-Alert-Format-Exposure'
  #     file_extension = 'xlsx'
  #     patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
  #       data = sara_alert_format(group)
  #       lookups << get_file(user_id, data, build_filename(base_filename, index + 1, file_extension), export_type)
  #     end
  #   when 'sara_format_isolation'
  #     patients = user.viewable_patients.where(isolation: true).where(purged: false)
  #     base_filename = 'Sara-Alert-Format-Isolation'
  #     file_extension = 'xlsx'
  #     patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
  #       data = sara_alert_format(group)
  #       lookups << get_file(user_id, data, build_filename(base_filename, index + 1, file_extension), export_type)
  #     end
  #   when 'full_history_all'
  #     patients = user.viewable_patients.where(purged: false)
  #     file_extension = 'xlsx'
  #     patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
  #       file_index = index + 1
  #       lookups << get_file(user_id,
  #                           excel_export_monitorees(group),
  #                           build_filename('Sara-Alert-Full-Export-Monitorees', file_index, file_extension),
  #                           export_type)
  #       lookups << get_file(user_id,
  #                           excel_export_assessments(group),
  #                           build_filename('Sara-Alert-Full-Export-Assessments', file_index, file_extension),
  #                           export_type)
  #       lookups << get_file(user_id,
  #                           excel_export_lab_results(group),
  #                           build_filename('Sara-Alert-Full-Export-Lab-Results', file_index, file_extension),
  #                           export_type)
  #       lookups << get_file(user_id,
  #                           excel_export_histories(group),
  #                           build_filename('Sara-Alert-Full-Export-Histories', file_index, file_extension),
  #                           export_type)
  #     end
  #   when 'full_history_purgeable'
  #     patients = user.viewable_patients.purge_eligible
  #     file_extension = 'xlsx'
  #     patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
  #       file_index = index + 1
  #       lookups << get_file(user_id,
  #                           excel_export_monitorees(group),
  #                           build_filename('Sara-Alert-Purge-Eligible-Export-Monitorees', file_index, file_extension),
  #                           export_type)
  #       lookups << get_file(user_id,
  #                           excel_export_assessments(group),
  #                           build_filename('Sara-Alert-Purge-Eligible-Export-Assessments', file_index, file_extension),
  #                           export_type)
  #       lookups << get_file(user_id,
  #                           excel_export_lab_results(group),
  #                           build_filename('Sara-Alert-Purge-Eligible-Export-Lab-Results', file_index, file_extension),
  #                           export_type)
  #       lookups << get_file(user_id,
  #                           excel_export_histories(group),
  #                           build_filename('Sara-Alert-Purge-Eligible-Export-Histories', file_index, file_extension),
  #                           export_type)
  #     end
  #   end
  #   return if lookups.empty?

  #   # Sort lookups by filename so that they are grouped together accordingly after batching
  #   lookups = lookups.sort_by { |lookup| lookup[:filename] }

  #   # Send an email to user
  #   UserMailer.download_email(user, export_type, lookups, RECORD_BATCH_SIZE).deliver_later
  # end
end
