# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :exports
  include ImportExport

  def perform(user_id, export_type)
    user = User.find_by(id: user_id)
    return if user.nil?

    # Delete any existing downloads of this type
    # This also queues the Rails attachment purge job to delete the file from S3
    user.downloads.where(export_type: export_type).delete_all

    # Construct export
    case export_type
    when 'csv_exposure'
      data = csv_line_list(user.viewable_patients.where(isolation: false).where(purged: false))
      download = create_download(user_id, data, build_filename('Sara-Alert-Linelist-Exposure', 'csv'), export_type, 'text/csv')
    when 'csv_isolation'
      data = csv_line_list(user.viewable_patients.where(isolation: true).where(purged: false))
      download = create_download(user_id, data, build_filename('Sara-Alert-Linelist-Isolation', 'csv'), export_type, 'text/csv')
    when 'sara_format_exposure'
      data = sara_alert_format(user.viewable_patients.where(isolation: false).where(purged: false))
      download = create_download(user_id, data, build_filename('Sara-Alert-Format-Exposure', 'xlsx'), export_type, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    when 'sara_format_isolation'
      data = sara_alert_format(user.viewable_patients.where(isolation: true).where(purged: false))
      download = create_download(user_id, data, build_filename('Sara-Alert-Format-Isolation', 'xlsx'), export_type, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    when 'full_history_all'
      patients = user.viewable_patients.where(purged: false)
      content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      download = create_download(user_id, excel_export_full_history(patients), build_filename('Sara-Alert-Full-Export-Monitorees', 'xlsx'), export_type, content_type)
    when 'full_history_purgeable'
      patients = user.viewable_patients.purge_eligible
      content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      download = create_download(user_id, excel_export_full_history(patients), build_filename('Sara-Alert-Purge-Eligible-Export-Monitorees', 'xlsx'), export_type, content_type)
    end
    # Send an email to user
    UserMailer.download_email(user, download).deliver_now
  end

  # Builds a file name using the base name, index, date, and extension.
  # Ex: "Sara-Alert-Linelist-Isolation-2020-09-01T14:15:05-04:00.csv"
  def build_filename(base_name, file_extension)
    "#{base_name}-#{DateTime.now}.#{file_extension}"
  end

  # Build and save the initial Download object and upload at least 1 export attachment to S3
  # Additional attachments can be chained off the returned download object
  def create_download(user_id, data, full_filename, export_type, content_type)
    download = Download.create(user_id: user_id, export_type: export_type, filename: full_filename)
    download.exports.attach(io: data, filename: full_filename, content_type: content_type)
    download
  end
end
