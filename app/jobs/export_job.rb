# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :exports
  include ImportExport
  include PatientQueryHelper
  include AssessmentQueryHelper
  include LaboratoryQueryHelper
  include CloseContactQueryHelper
  include TransferQueryHelper
  include HistoryQueryHelper

  # Limits number of records to be considered for a single exported file to handle maximum file size limit.
  # Adds additional files as needed if records exceeds batch size.
  RECORD_BATCH_SIZE = 10_000

  def perform(config)
    # Get user in order to query viewable patients
    user = User.find_by(id: config[:user_id])
    return if user.nil?

    # Delete any existing downloads of this type
    user.downloads.where(export_type: config[:export_type]).delete_all

    # Extract data
    data = config[:data]
    return if data.nil?

    # Construct export
    lookups = []
    patients = patients_by_query(user, data.dig(:patients, :query) || {})
    patients&.in_batches(of: RECORD_BATCH_SIZE)&.each_with_index do |patients_group, index|
      exported_data = get_export_data(patients_group, data)
      files = write_export_data_to_file(config, exported_data, index)
      lookups.concat(create_lookups(config, files))
    end

    return if lookups.empty?

    # Sort lookups by filename so that they are grouped together accordingly after batching
    lookups = lookups.sort_by { |lookup| lookup[:filename] }

    # Send an email to user
    UserMailer.download_email(user, EXPORT_TYPES[config[:export_type]][:label] || 'default', lookups, RECORD_BATCH_SIZE).deliver_later
  end

  # Writes export data to file(s)
  def write_export_data_to_file(config, exported_data, index)
    case config[:format]
    when 'csv'
      csv_export(config, exported_data, index)
    when 'xlsx'
      xlsx_export(config, exported_data, index)
    end
  end

  # Creates lookups for files
  def create_lookups(config, files)
    lookups = []

    # Write
    files&.each do |file|
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
      lookups << { lookup: lookup, filename: file[:filename] }
    end

    lookups
  end

  # Creates a list of csv files from exported data
  def csv_export(config, exported_data, index)
    files = []
    CUSTOM_EXPORT_OPTIONS.each_key do |data_type|
      next unless config.dig(:data, data_type, :checked).present?

      package = CSV.generate(headers: true) do |csv|
        fields = config[:data][data_type][:checked]
        csv << fields.map { |field| ALL_FIELDS_NAMES[data_type][field] }
        exported_data[data_type].each do |record|
          csv << fields.map { |field| record[field] }
        end
      end
      files << { filename: build_filename(config, data_type, index), content: Base64.encode64(package) }
    end
    files
  end

  # Creates a list of excel files from exported data
  def xlsx_export(config, exported_data, index)
    Axlsx::Package.new do |p|
      CUSTOM_EXPORT_OPTIONS.each_key do |data_type|
        next unless config.dig(:data, data_type, :checked).present?

        p.workbook.add_worksheet(name: CUSTOM_EXPORT_OPTIONS[data_type][:label]) do |sheet|
          fields = config[:data][data_type][:checked]
          sheet.add_row(fields.map { |field| ALL_FIELDS_NAMES[data_type][field] })
          exported_data[data_type].each do |record|
            sheet.add_row(fields.map { |field| record[field] }, { types: Array.new(fields.length, :string) })
          end
        end
      end
      return [{ filename: build_filename(config, nil, index), content: Base64.encode64(p.to_stream.read) }]
    end
  end

  # Builds a file name using the base name, index, date, and extension.
  # Ex: "Sara-Alert-Linelist-Isolation-2020-09-01T14:15:05-04:00-1"
  def build_filename(config, data_type, index)
    data_type_name = data_type.present? && CUSTOM_EXPORT_OPTIONS[data_type].present? ? CUSTOM_EXPORT_OPTIONS[data_type][:label] : nil
    base_name = "#{config[:filename].present? ? config[:filename] : EXPORT_TYPES[config[:export_type]][:filename]}#{data_type_name ? "-#{data_type_name}" : ''}"
    "#{base_name}-#{DateTime.now}-#{index}.#{config[:format]}"
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
