# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :default
  include ImportExport

  # Limits number of records to be considered for a single exported file to handle maximum file size limit.
  # Adds additional files as needed if records exceeds batch size.
  RECORD_BATCH_SIZE = 10_000

  def perform(user_id, export_type)
    user = User.find_by(id: user_id)
    return if user.nil?

    # Delete any existing downloads of this type
    user.downloads.where(export_type: export_type).delete_all

    # Construct export
    lookups = []
    case export_type
    when 'csv_exposure'
      patients = user.viewable_patients.where(isolation: false).where(purged: false)
      filename = 'Sara-Alert-Linelist-Exposure'
      file_extension = 'csv'
      patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
        data = csv_line_list(group)
        lookups << get_file(user_id, data, filename, file_extension, export_type, index + 1)
      end
    when 'csv_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = 'Sara-Alert-Linelist-Isolation'
      file_extension = 'csv'
      patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
        data = csv_line_list(group)
        lookups << get_file(user_id, data, filename, file_extension, export_type, index + 1)
      end
    when 'sara_format_exposure'
      patients = user.viewable_patients.where(isolation: false).where(purged: false)
      filename = 'Sara-Alert-Format-Exposure'
      file_extension = 'xlsx'
      patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
        data = sara_alert_format(group)
        lookups << get_file(user_id, data, filename, file_extension, export_type, index + 1)
      end
    when 'sara_format_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = 'Sara-Alert-Format-Isolation'
      file_extension = 'xlsx'
      patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
        data = sara_alert_format(group)
        lookups << get_file(user_id, data, filename, file_extension, export_type, index + 1)
      end
    when 'full_history_all'
      patients = user.viewable_patients.where(purged: false)
      file_extension = 'xlsx'
      patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
        file_index = index + 1
        lookups << get_file(user_id, excel_export_monitorees(group), 'Sara-Alert-Full-Export-Monitorees', file_extension, export_type, file_index)
        lookups << get_file(user_id, excel_export_assessments(group), 'Sara-Alert-Full-Export-Assessments', file_extension, export_type, file_index)
        lookups << get_file(user_id, excel_export_lab_results(group), 'Sara-Alert-Full-Export-Lab-Results', file_extension, export_type, file_index)
        lookups << get_file(user_id, excel_export_histories(group), 'Sara-Alert-Full-Export-Histories', file_extension, export_type, file_index)
      end
    when 'full_history_purgeable'
      patients = user.viewable_patients.purge_eligible
      patients.in_batches(of: RECORD_BATCH_SIZE).each_with_index do |group, index|
        file_index = index + 1
        lookups << get_file(user_id, excel_export_monitorees(group), 'Sara-Alert-Purge-Eligible-Export-Monitorees', file_extension, export_type, file_index)
        lookups << get_file(user_id, excel_export_assessments(group), 'Sara-Alert-Purge-Eligible-Export-Assessments', file_extension, export_type, file_index)
        lookups << get_file(user_id, excel_export_lab_results(group), 'Sara-Alert-Purge-Eligible-Export-Lab-Results', file_extension, export_type, file_index)
        lookups << get_file(user_id, excel_export_histories(group), 'Sara-Alert-Purge-Eligible-Export-Histories', file_extension, export_type, file_index)
      end
    end
    return if lookups.empty?

    puts "lookups: #{lookups}"
    # Send an email to user
    UserMailer.download_email(user, export_type, lookups).deliver_later
  end

  # Gets a single download with the provided filename information and containing the provided data.
  # rubocop:disable Metrics/ParameterLists
  def get_file(user_id, data, filename, file_extension, export_type, file_index)
    full_filename = "#{filename}-#{DateTime.now}-#{file_index}.#{file_extension}"
    { lookup: save_download(user_id, data, full_filename, export_type), filename: full_filename }
  end
  # rubocop:enable Metrics/ParameterLists

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
end
