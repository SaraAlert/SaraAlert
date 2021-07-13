# frozen_string_literal: true

require 'api_controller_test_case'

class BulkExportTest < ApiControllerTestCase
  def setup
    setup_system_applications
    setup_system_tokens
    setup_user_applications
    setup_logger
    @patient = create(:patient)
    @patient_io = StringIO.new
    @patient_io.write(JSON.generate(@patient.as_fhir.to_hash) + "\n")
    @patient_io.rewind

    @observation = create(:laboratory)
    @observation_io = StringIO.new
    @observation_io.write(JSON.generate(@observation.as_fhir.to_hash) + "\n")
    @observation_io.rewind
  end

  #----- $export tests -----
  test 'should kick off an export' do
    get(
      '/fhir/r4/Patient/$export',
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :accepted
    download_id = response.headers['Content-Location'].split('/').last
    assert_not_nil download_id
    assert_enqueued_jobs 1
    assert_enqueued_with(job: ExportFhirJob, args: [@system_everything_app, ApiDownload.find_by_id(download_id), { since: nil }])
  end

  test 'should kick off an export with _since parameter' do
    since = 2.days.ago.strftime('%FT%T%:z')
    get(
      "/fhir/r4/Patient/$export?_since=#{CGI.escape(since)}",
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :accepted
    download_id = response.headers['Content-Location'].split('/').last
    assert_not_nil download_id
    assert_enqueued_jobs 1
    assert_enqueued_with(job: ExportFhirJob, args: [@system_everything_app, ApiDownload.find_by_id(download_id), { since: DateTime.parse(since) }])
  end

  test 'should be 422 unprocessable when _since is invalid' do
    since = 'foo'
    get(
      "/fhir/r4/Patient/$export?_since=#{CGI.escape(since)}",
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :unprocessable_entity
  end

  test 'should be 422 unprocessable when _type is passed' do
    get(
      '/fhir/r4/Patient/$export?_type=foo',
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :unprocessable_entity
  end

  test 'should be 422 unprocessable when _outputFormat is passed' do
    get(
      '/fhir/r4/Patient/$export?_outputFormat=foo',
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :unprocessable_entity
  end

  test 'should be 403 forbidden when required scopes are missing' do
    get(
      '/fhir/r4/Patient/$export',
      headers: {
        Authorization: "Bearer #{@system_patient_token_rw.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :forbidden
  end

  test 'should be 406 not acceptable with incorrect Accept header' do
    get(
      '/fhir/r4/Patient/$export',
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/json',
        Prefer: 'respond-async'
      }
    )
    assert_response :not_acceptable
    json_response = JSON.parse(response.body)
    assert_match(%r{Accept.*application/fhir\+json}, json_response['issue'][0]['diagnostics'])
  end

  test 'should be 401 unauthorized with no client application' do
    get(
      '/fhir/r4/Patient/$export',
      headers: {
        Authorization: "Bearer #{@user_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_match(/Backend Services/, json_response['issue'][0]['diagnostics'])
  end

  test 'should be 429 too many requests with subsequent requests' do
    get(
      '/fhir/r4/Patient/$export',
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :accepted
    get(
      '/fhir/r4/Patient/$export',
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+json',
        Prefer: 'respond-async'
      }
    )
    assert_response :too_many_requests
    json_response = JSON.parse(response.body)
    assert_match(/already initiated an export/, json_response['issue'][0]['diagnostics'])
  end

  #----- ExportStatus tests -----
  test 'should be 202 accepted for an in progress job' do
    download = create(:api_download, application_id: @system_everything_app.id)
    allow(::Sidekiq::Status).to(receive(:status).and_return(:working))
    get(
      "/fhir/r4/ExportStatus/#{download.id}",
      headers: { Authorization: "Bearer #{@system_everything_token.token}" }
    )
    assert_response :accepted
  end

  test 'should be 200 ok for a complete job' do
    download = create(:api_download, application_id: @system_everything_app.id)
    allow(::Sidekiq::Status).to(receive(:status).and_return(:complete))
    allow(::Sidekiq::Status).to(receive(:get).and_return(DateTime.now.utc.to_s))
    get(
      "/fhir/r4/ExportStatus/#{download.id}",
      headers: { Authorization: "Bearer #{@system_everything_token.token}" }
    )
    assert_response :ok
  end

  test 'should be 500 server error for a failed job' do
    download = create(:api_download, application_id: @system_everything_app.id)
    allow(::Sidekiq::Status).to(receive(:status).and_return(:failed))
    get(
      "/fhir/r4/ExportStatus/#{download.id}",
      headers: { Authorization: "Bearer #{@system_everything_token.token}" }
    )
    assert_response :internal_server_error
  end

  test 'should be 404 not found for a job that does not exist' do
    download = create(:api_download, application_id: @system_everything_app.id)
    allow(::Sidekiq::Status).to(receive(:status).and_return(nil))
    get(
      "/fhir/r4/ExportStatus/#{download.id}",
      headers: { Authorization: "Bearer #{@system_everything_token.token}" }
    )
    assert_response :not_found
  end

  #----- ExportFiles tests -----
  test 'should return an exported file' do
    download = create(:api_download, application_id: @system_everything_app.id)
    download.files.attach(io: @patient_io, filename: 'Patient.ndjson', content_type: 'application/fhir+ndjson')
    @system_everything_app.api_downloads << download
    get(
      "/fhir/r4/ExportFiles/#{download.id}/Patient",
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/fhir+ndjson'
      }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal @patient.as_fhir.to_hash, json_response
  end

  test 'should only require the scope of the resources in the exported file' do
    download = create(:api_download, application_id: @system_patient_read_app.id)
    download.files.attach(io: @patient_io, filename: 'Patient.ndjson', content_type: 'application/fhir+ndjson')
    @system_patient_read_app.api_downloads << download
    get(
      "/fhir/r4/ExportFiles/#{download.id}/Patient",
      headers: {
        Authorization: "Bearer #{@system_patient_token_r.token}",
        Accept: 'application/fhir+ndjson'
      }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal @patient.as_fhir.to_hash, json_response
  end

  test 'should be 406 not acceptable when incorrect accept header' do
    download = create(:api_download, application_id: @system_everything_app.id)
    download.files.attach(io: @patient_io, filename: 'Patient.ndjson', content_type: 'application/fhir+ndjson')
    @system_everything_app.api_downloads << download
    get(
      "/fhir/r4/ExportFiles/#{download.id}/Patient",
      headers: {
        Authorization: "Bearer #{@system_everything_token.token}",
        Accept: 'application/xml'
      }
    )
    assert_response :not_acceptable
    json_response = JSON.parse(response.body)
    assert_match(/Accept/, json_response['issue'][0]['diagnostics'])
  end

  test 'should be not found when the file does not match an expected resource_type' do
    download = create(:api_download, application_id: @system_patient_read_app.id)
    download.files.attach(io: @patient_io, filename: 'foo.ndjson', content_type: 'application/fhir+ndjson')
    @system_patient_read_app.api_downloads << download
    get(
      "/fhir/r4/ExportFiles/#{download.id}/foo",
      headers: {
        Authorization: "Bearer #{@system_patient_token_r.token}",
        Accept: 'application/fhir+ndjson'
      }
    )
    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_match(/Invalid ResourceType.*foo/, json_response['issue'][0]['diagnostics'])
  end

  test 'should be not found when the file does not exist' do
    download = create(:api_download, application_id: @system_everything_app.id)
    get(
      "/fhir/r4/ExportFiles/#{download.id}/Patient",
      headers: {
        Authorization: "Bearer #{@system_patient_token_r.token}",
        Accept: 'application/fhir+ndjson'
      }
    )
    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_match(/No file found/, json_response['issue'][0]['diagnostics'])
  end

  test 'should be unauthorized when the client application has no available downloads' do
    download = create(:api_download, application_id: @system_everything_app.id)
    get(
      "/fhir/r4/ExportFiles/#{download.id}/Patient",
      headers: {
        Authorization: "Bearer #{@system_patient_token_r.token}",
        Accept: 'application/fhir+ndjson'
      }
    )
    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_match(/No file found/, json_response['issue'][0]['diagnostics'])
  end
end
