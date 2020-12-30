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

    # NOTE: The reorder here clears out any other sorting that may have been added to this query as it should just be sorting by ID when
    # getting batches. in_batches appears to NOT sort within batches, so ordering is also done deeper down.
    patients.reorder('').in_batches(of: RECORD_BATCH_SIZE).each_with_index do |patients_group, index|
      files = write_export_data_to_files(config, patients_group, index)
      lookups.concat(create_lookups(config, files))
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
