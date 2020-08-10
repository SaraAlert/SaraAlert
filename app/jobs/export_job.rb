# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :default
  include ImportExport

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
      filename = "Sara-Alert-Linelist-Exposure-#{DateTime.now}.csv"
      data = csv_line_list(patients)
      lookups << { lookup: save_download(user_id, data, filename, export_type), filename: filename }
    when 'csv_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = "Sara-Alert-Linelist-Isolation-#{DateTime.now}.csv"
      data = csv_line_list(patients)
      lookups << { lookup: save_download(user_id, data, filename, export_type), filename: filename }
    when 'sara_format_exposure'
      patients = user.viewable_patients.where(isolation: false).where(purged: false)
      filename = "Sara-Alert-Format-Exposure-#{DateTime.now}.xlsx"
      data = sara_alert_format(patients)
      lookups << { lookup: save_download(user_id, data, filename, export_type), filename: filename }
    when 'sara_format_isolation'
      patients = user.viewable_patients.where(isolation: true).where(purged: false)
      filename = "Sara-Alert-Format-Isolation-#{DateTime.now}.xlsx"
      data = sara_alert_format(patients)
      lookups << { lookup: save_download(user_id, data, filename, export_type), filename: filename }
    when 'full_history_all'
      patients = user.viewable_patients.where(purged: false)
      lookups << { lookup: save_download(user_id,
                                         excel_export_monitorees(patients),
                                         "Sara-Alert-Full-Export-Monitorees-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Full-Export-Monitorees-#{DateTime.now}.xlsx" }
      lookups << { lookup: save_download(user_id,
                                         excel_export_assessments(patients),
                                         "Sara-Alert-Full-Export-Assessments-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Full-Export-Assessments-#{DateTime.now}.xlsx" }
      lookups << { lookup: save_download(user_id,
                                         excel_export_lab_results(patients),
                                         "Sara-Alert-Full-Export-Lab-Results-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Full-Export-Lab-Results-#{DateTime.now}.xlsx" }
      lookups << { lookup: save_download(user_id,
                                         excel_export_histories(patients),
                                         "Sara-Alert-Full-Export-Histories-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Full-Export-Histories-#{DateTime.now}.xlsx" }
    when 'full_history_purgeable'
      patients = user.viewable_patients.purge_eligible
      lookups << { lookup: save_download(user_id,
                                         excel_export_monitorees(patients),
                                         "Sara-Alert-Purge-Eligible-Export-Monitorees-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Purge-Eligible-Export-Monitorees-#{DateTime.now}.xlsx" }
      lookups << { lookup: save_download(user_id,
                                         excel_export_assessments(patients),
                                         "Sara-Alert-Purge-Eligible-Export-Assessments-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Purge-Eligible-Export-Assessments-#{DateTime.now}.xlsx" }
      lookups << { lookup: save_download(user_id,
                                         excel_export_lab_results(patients),
                                         "Sara-Alert-Purge-Eligible-Export-Lab-Results-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Purge-Eligible-Export-Lab-Results-#{DateTime.now}.xlsx" }
      lookups << { lookup: save_download(user_id,
                                         excel_export_histories(patients),
                                         "Sara-Alert-Purge-Eligible-Export-Histories-#{DateTime.now}.xlsx",
                                         export_type),
                   filename: "Sara-Alert-Purge-Eligible-Export-Histories-#{DateTime.now}.xlsx" }
    end
    return if lookups.empty?

    # Send an email to user
    UserMailer.download_email(user, export_type, lookups).deliver_later
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
end
