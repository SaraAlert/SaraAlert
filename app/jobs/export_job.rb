# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :exports
  include ImportExport

  # Inner batch size limits number of Patient records details help in memory at once before writing to file.
  INNER_BATCH_SIZE = ENV.fetch('EXPORT_INNER_BATCH_SIZE', 500).to_i unless const_defined?(:INNER_BATCH_SIZE)

  def perform(config)
    # Get user in order to query viewable patients
    user = User.find_by(id: config[:user_id])
    return if user.nil?

    # Delete any existing downloads of this type
    # Destroy all must be called on the downloads because the after destroy callback must be executed to remove the blobs from object storage
    user.downloads.where(export_type: config[:export_type]).destroy_all

    # Extract data
    data = config[:data]
    return if data.nil?

    # Construct export
    query = data.dig(:patients, :query) || {}
    patients = patients_by_query(user, query)
    files = write_export_data_to_files(config, patients, INNER_BATCH_SIZE)
    downloads = create_downloads(config, files).sort_by { |download| download[:filename] }

    # Send an email to user
    UserMailer.download_email(user, EXPORT_TYPES[config[:export_type]][:label] || 'default', downloads).deliver_later
  end

  private

  # Creates downloads for files
  def create_downloads(config, files)
    downloads = []
    # Write
    files&.each do |file|
      content_type = config[:format] == 'csv' ? 'text/csv' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      downloads << create_download(config[:user_id], file[:content], file[:filename], config[:export_type], content_type)
    end
    downloads
  end

  # Build and save the initial Download object and upload at least 1 export attachment to S3
  # Additional attachments can be chained off the returned download object
  def create_download(user_id, data, full_filename, export_type, content_type)
    download = Download.create(user_id: user_id, export_type: export_type, filename: full_filename)
    download.export_files.attach(io: data, filename: full_filename, content_type: content_type)
    download
  ensure
    FileUtils.remove_entry(File.dirname(data)) if data.is_a?(File) && File.exist?(data)
  end
end
