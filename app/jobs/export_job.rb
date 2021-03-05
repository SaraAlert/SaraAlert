# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :exports
  include ImportExport

  # Limits number of Patient records to be considered for a single exported file to handle maximum file size limit.
  # Adds additional files as needed if exceeds batch size.
  OUTER_BATCH_SIZE = ENV['EXPORT_OUTER_BATCH_SIZE']&.to_i || 10_000

  # Inner batch size limits number of Patient records details help in memory at once before writing to file.
  INNER_BATCH_SIZE = ENV['EXPORT_INNER_BATCH_SIZE']&.to_i || 500

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
    patients = patients_by_query(user, data.dig(:patients, :query) || {})
    files = write_export_data_to_files(config, patients, OUTER_BATCH_SIZE, INNER_BATCH_SIZE)
    return unless files.present?

    # Sort files by filename so that they are grouped together accordingly after batching
    files = files.sort_by { |file| file[:filename] }

    # Send an email to user
    UserMailer.download_email(user, EXPORT_TYPES[config[:export_type]][:label] || 'default', files, OUTER_BATCH_SIZE).deliver_later
  end
end
