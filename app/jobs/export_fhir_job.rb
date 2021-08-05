# frozen_string_literal: true

# ExportFhirJob: prepare a FHIR export for a client application
class ExportFhirJob < ApplicationJob
  queue_as :exports
  include Sidekiq::Status::Worker
  sidekiq_options retry: 0

  # Batch size limits number of Patient records details help in memory at once before writing to file.
  BATCH_SIZE = ENV.fetch('EXPORT_INNER_BATCH_SIZE', 500).to_i unless const_defined?(:BATCH_SIZE)
  NUM_EXPORTS = 6

  def perform(current_client_application, download, params)
    start_time = DateTime.now.utc
    patient_ids = Jurisdiction.find_by(id: current_client_application[:jurisdiction_id])&.all_patients_excluding_purged&.pluck(:id)
    return if patient_ids.nil?

    # Store transaction_time via sidekiq-status gem to be retrieved when returning completed status
    store(transaction_time: start_time)

    # Track progress using methods from sidekiq-status gem so that percentage complete can be
    # displayed when current status is requested. Total is 6 for 6 possible resourceTypes
    total(6)
    progress = 0
    at(progress)

    patient_query = { id: patient_ids }
    patient_query[:updated_at] = (params[:since]..) unless params[:since].nil?
    add_file(download, Patient.where(patient_query), 'Patient.ndjson', start_time)
    at(progress += 1)
    resource_query = { patient_id: patient_ids }
    resource_query[:updated_at] = (params[:since]..) unless params[:since].nil?
    add_file(download, Assessment.where(resource_query), 'QuestionnaireResponse.ndjson', start_time)
    at(progress += 1)
    add_file(download, History.where(resource_query), 'Provenance.ndjson', start_time)
    at(progress += 1)
    add_file(download, Laboratory.where(resource_query), 'Observation.ndjson', start_time)
    at(progress += 1)
    add_file(download, Vaccine.where(resource_query), 'Immunization.ndjson', start_time)
    at(progress + 1)
    add_file(download, CloseContact.where(resource_query), 'RelatedPerson.ndjson', start_time)

    # Remove any old downloads besides the current one
    current_client_application.api_downloads.where.not(id: download.id).destroy_all
    current_client_application.api_downloads << download
  rescue ExportFhirJob::ExpiredExportError
    current_client_application.api_downloads.destroy_all
    nil
  end

  class ExpiredExportError < StandardError; end

  private

  def add_file(download, records, filename, start_time)
    return if records.empty?

    file = Tempfile.new
    records.in_batches(of: BATCH_SIZE).each do |batch|
      batch.each do |r|
        raise ExpiredExportError if DateTime.now.utc > start_time + Rails.configuration.api['bulk_export_expiration_minutes'].minutes

        file.write(JSON.generate(r.as_fhir.to_hash) + "\n")
      end
    end
    file.rewind
    download.files.attach(io: file, filename: filename, content_type: 'application/fhir+ndjson')
  ensure
    file&.close
    file.unlink if file.is_a?(File) && File.exist?(file)
  end
end
