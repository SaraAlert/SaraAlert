# frozen_string_literal: true

# ExportFhirJob: prepare a FHIR export for a client application
class ExportFhirJob < ApplicationJob
  queue_as :exports
  include Sidekiq::Status::Worker
  sidekiq_options retry: 0

  def perform(current_client_application, download)
    patients = Jurisdiction.find_by(id: current_client_application[:jurisdiction_id])&.all_patients_excluding_purged
    return if patients.nil?

    store transaction_time: DateTime.now.utc.strftime('%FT%T%:z')

    patient_ids = patients.pluck(:id)
    add_file(download, patients, 'Patient.ndjson')
    add_file(download, Assessment.where(patient_id: patient_ids), 'QuestionnaireResponse.ndjson')
    add_file(download, History.where(patient_id: patient_ids), 'Provenance.ndjson')
    add_file(download, Laboratory.where(patient_id: patient_ids), 'Observation.ndjson')
    add_file(download, Vaccine.where(patient_id: patient_ids), 'Immunization.ndjson')
    add_file(download, CloseContact.where(patient_id: patient_ids), 'RelatedPerson.ndjson')

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
    FileUtils.remove_entry(File.dirname(file)) if file.is_a?(File) && File.exist?(file)
  end
end
