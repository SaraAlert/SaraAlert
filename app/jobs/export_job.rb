# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :default
  include ImportExportHelper

  def perform(user_id, export_type)
    user = User.find_by(id: user_id)
    return if user.nil?

    # Construct export
    case export_type
    when 'csv_exposure'
      patients = user.viewable_patients.where(isolation: false).where(purged: false)
      filename = "Sara-Alert-Exposure-#{export_type.capitalize}-#{DateTime.now}.csv"
      data = csv_line_list(patients)
    when 'csv_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = "Sara-Alert-Isolation-#{export_type.capitalize}-#{DateTime.now}.csv"
      data = csv_line_list(patients)
    when 'sara_format_exposure'
      patients = user.viewable_patients.where(isolation: false).where(purged: false)
      filename = "Sara-Alert-Format-Exposure-#{DateTime.now}.xlsx"
      data = sara_alert_format(patients)
    when 'sara_format_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = "Sara-Alert-Format-Isolation-#{DateTime.now}.xlsx"
      data = sara_alert_format(patients)
    when 'full_history_all'
      patients = user.viewable_patients.where(purged: false)
      filename = "Sara-Alert-Full-Export-#{DateTime.now}.xlsx"
      data = build_excel_export_for_patients(patients)
    when 'full_history_purgable'
      patients = user.viewable_patients.purge_eligible
      filename = "Sara-Alert-Purge-Eligable-Export-#{DateTime.now}.xlsx"
      data = build_excel_export_for_patients(patients)
    end
    return if data.blank?

    # Construct download object from export data and save (overwrite any of existing type for this user)
    existing_download = user.downloads.find_by(export_type: export_type)
    existing_download&.destroy!
    download = Download.new(user_id: user_id, contents: data, filename: filename, lookup: SecureRandom.uuid, export_type: export_type)
    return unless download.save

    # Send an email to user
    UserMailer.download_email(user, export_type, download.lookup).deliver_later
  end
end
