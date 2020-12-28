# frozen_string_literal: true

# ExportJob: prepare an export for a user
class ExportJob < ApplicationJob
  queue_as :exports
  include ImportExport

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

    # Custom export is already sorted by id, calling order on custom export patients leads to invalid SQL statement because id is not in select list
    patients = patients.order(:id) unless config[:export_type] == :custom
    patients.find_in_batches(batch_size: RECORD_BATCH_SIZE).with_index do |patients_group, index|
      # Duplicate the config as it gets changed in the following method calls and should be fresh each batch.
      config_dup = config.deep_dup
      exported_data = get_export_data(patients_group, config_dup[:data])
      files = write_export_data_to_files(config_dup, exported_data, index)
      lookups.concat(create_lookups(config_dup, files))
    end

    return if lookups.empty?

    # Sort lookups by filename so that they are grouped together accordingly after batching
    lookups = lookups.sort_by { |lookup| lookup[:filename] }

    # Send an email to user
    UserMailer.download_email(user, EXPORT_TYPES[config[:export_type]][:label] || 'default', lookups, RECORD_BATCH_SIZE).deliver_later
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
end
