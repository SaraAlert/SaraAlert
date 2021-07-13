# frozen_string_literal: true

# ExportFhirJob: prepare a FHIR export for a client application
class ExportFhirJob < ApplicationJob
  queue_as :exports
  include Sidekiq::Status::Worker
  sidekiq_options retry: 0

  def perform(current_client_application, download, params)
    patient_ids = Jurisdiction.find_by(id: current_client_application[:jurisdiction_id])&.all_patients_excluding_purged&.pluck(:id)
    return if patient_ids.nil?

    store transaction_time: DateTime.now.utc

    patient_query = { id: patient_ids }
    patient_query[:updated_at] = (params[:since]..) unless params[:since].nil?
    add_file(download, Patient.where(patient_query), 'Patient.ndjson')

    resource_query = { patient_id: patient_ids }
    resource_query[:updated_at] = (params[:since]..) unless params[:since].nil?
    add_file(download, Assessment.where(resource_query), 'QuestionnaireResponse.ndjson')
    add_file(download, History.where(resource_query), 'Provenance.ndjson')
    add_file(download, Laboratory.where(resource_query), 'Observation.ndjson')
    add_file(download, Vaccine.where(resource_query), 'Immunization.ndjson')
    add_file(download, CloseContact.where(resource_query), 'RelatedPerson.ndjson')

    # Remove any old downloads besides the current one
    current_client_application.api_downloads.where.not(id: download.id).destroy_all
    current_client_application.api_downloads << download
  end

  private

  def add_file(download, records, filename)
    return if records.empty?

    file = Tempfile.new
    records.each { |r| file.write(JSON.generate(r.as_fhir.to_hash) + "\n") }
    file.rewind
    download.files.attach(io: file, filename: filename, content_type: 'application/fhir+ndjson')
  ensure
    file&.close
    FileUtils.remove_entry(File.dirname(file)) if file.is_a?(File) && File.exist?(file)
  end
end
