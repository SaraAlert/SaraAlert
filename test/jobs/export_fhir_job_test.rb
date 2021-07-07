# frozen_string_literal: true

require 'test_case'

class ExportFhirJobTest < ActiveSupport::TestCase
  def setup
    @shadow_user = create(:public_health_enroller_user, is_api_proxy: true, api_enabled: true)
    @client_app = create(
      :oauth_application,
      user_id: @shadow_user.id,
      jurisdiction_id: @shadow_user.jurisdiction_id
    )
    @patient = create(:patient, creator: @shadow_user)
    @lab = create(:laboratory, patient_id: @patient.id)
    @assessment = create(:assessment, patient_id: @patient.id)
    create(:reported_condition, assessment_id: @assessment.id)
    @history = create(:history, patient_id: @patient.id)
    @vaccine = create(:vaccine, patient_id: @patient.id)
    @close_contact = create(:close_contact, patient_id: @patient.id)

    @download = create(:api_download, application_id: @client_app.id)
  end

  test 'should add files for all resource_types when they are present' do
    ExportFhirJob.perform_now(@client_app, @download, {})
    assert_equal 6, @download.files.count

    patient = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Patient.ndjson')&.download
    assert_equal @patient.as_fhir.to_hash, JSON.parse(patient)

    lab = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Observation.ndjson')&.download
    assert_equal @lab.as_fhir.to_hash, JSON.parse(lab)

    assessment = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'QuestionnaireResponse.ndjson')&.download
    assert_equal @assessment.as_fhir.to_hash, JSON.parse(assessment)

    history = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Provenance.ndjson')&.download
    assert_equal @history.as_fhir.to_hash, JSON.parse(history)

    vaccine = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Immunization.ndjson')&.download
    assert_equal @vaccine.as_fhir.to_hash, JSON.parse(vaccine)

    close_contact = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'RelatedPerson.ndjson')&.download
    assert_equal @close_contact.as_fhir.to_hash, JSON.parse(close_contact)
  end

  test 'should only add files for resources updated since the since date, if since is given' do
    @lab.update(updated_at: 3.days.ago)
    @assessment.update(updated_at: 3.days.ago)
    @patient.reload
    ExportFhirJob.perform_now(@client_app, @download, { since: 2.days.ago })

    # No assessment or lab, because those have not been updated since the since parameter
    assert_equal 4, @download.files.count

    patient = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Patient.ndjson')&.download
    assert_equal @patient.as_fhir.to_hash, JSON.parse(patient)

    history = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Provenance.ndjson')&.download
    assert_equal @history.as_fhir.to_hash, JSON.parse(history)

    vaccine = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Immunization.ndjson')&.download
    assert_equal @vaccine.as_fhir.to_hash, JSON.parse(vaccine)

    close_contact = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'RelatedPerson.ndjson')&.download
    assert_equal @close_contact.as_fhir.to_hash, JSON.parse(close_contact)
  end

  test 'should not add files for a given resource_type if that type is not present in the jurisdiction' do
    @vaccine.update(patient_id: create(:patient).id)
    @patient.reload
    ExportFhirJob.perform_now(@client_app, @download, {})
    assert_equal 5, @download.files.count

    patient = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Patient.ndjson')&.download
    assert_equal @patient.as_fhir.to_hash, JSON.parse(patient)

    lab = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Observation.ndjson')&.download
    assert_equal @lab.as_fhir.to_hash, JSON.parse(lab)

    assessment = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'QuestionnaireResponse.ndjson')&.download
    assert_equal @assessment.as_fhir.to_hash, JSON.parse(assessment)

    history = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'Provenance.ndjson')&.download
    assert_equal @history.as_fhir.to_hash, JSON.parse(history)

    close_contact = ActiveStorage::Blob.where(id: @download.files.pluck(:blob_id)).find_by(filename: 'RelatedPerson.ndjson')&.download
    assert_equal @close_contact.as_fhir.to_hash, JSON.parse(close_contact)
  end

  test 'should do nothing if the jurisdiction has no accessible patients' do
    @client_app.jurisdiction_id = create(:jurisdiction)
    ExportFhirJob.perform_now(@client_app, @download, {})
    assert_equal 0, @download.files.count
  end

  test 'should destroy existing downloads when generating a new one' do
    create(:api_download, application_id: @client_app.id)
    assert_equal 2, @client_app.api_downloads.count
    ExportFhirJob.perform_now(@client_app, @download, {})
    assert_equal 1, @client_app.api_downloads.count
  end
end
