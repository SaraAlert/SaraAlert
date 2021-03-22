# frozen_string_literal: true

require 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'controllers/fhir/r4/api_controller_test'

# rubocop:disable Metrics/ClassLength
class ApiControllerTest < ActionDispatch::IntegrationTest
  #----- show tests -----

  test 'should get patient via show' do
    patient_id = 1
    patient = Patient.find_by(id: patient_id)
    resource_path = "/fhir/r4/Patient/#{patient_id}"
    get(
      resource_path,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert_equal 'Telephone call', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Morning', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert_equal 45.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'last-date-of-exposure' }.first['valueDate']
    assert_equal 5.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert_not json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
    assert_equal resource_path, json_response['contained'].first['target'].first['reference']
    assert_equal Patient.find_by(id: patient_id).creator_id, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal Patient.find_by(id: patient_id).creator.email, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
    assert_equal patient.user_defined_id_statelocal, json_response['identifier'].find { |i| i['system'].include? 'state-local-id' }['value']
  end

  test 'should get patient via show using _format parameter' do
    get(
      '/fhir/r4/Patient/1?' + { _format: 'application/fhir+json' }.to_param,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}" }
    )
    assert_response :ok
  end

  test 'SYSTEM FLOW: patients within exact jurisdiction should be accessible' do
    # Same jurisdiction
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
  end

  test 'SYSTEM FLOW: patients within subjurisdictions should be accessible' do
    # Update jurisdiction to be subjurisdiction
    Patient.find_by(id: 1).update!(jurisdiction_id: 4)
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
  end

  test 'SYSTEM FLOW: patients outside of jurisdiction should NOT be accessible' do
    # Update jurisdiction to be out of scope
    Patient.find_by(id: 1).update!(jurisdiction_id: 1)
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: analysts should not have any access to patients' do
    @user = User.find_by(email: 'analyst_all@example.com')
    @user.update!(api_enabled: true)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_write_app,
      scopes: 'user/Patient.*'
    )
    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: enrollers should only have access to enrolled patients' do
    # Created patient should be okay
    @user = User.find_by(email: 'state1_enroller@example.com')
    @user.update!(api_enabled: true, jurisdiction_id: 2)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(
      resource_owner_id: @user.id,
      application: @user_patient_read_write_app,
      scopes: 'user/Patient.*'
    )
    Patient.find_by(id: 1).update!(creator_id: @user[:id])

    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']

    # Not created patient should be forbidden okay
    get(
      '/fhir/r4/Patient/2',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :forbidden
  end

  test 'USER FLOW: epis should have access to all patients within jurisdiction' do
    @user = User.find_by(email: 'state1_epi@example.com')
    @user.update!(api_enabled: true, jurisdiction_id: 2)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application: @user_patient_read_write_app, scopes: 'user/Patient.*')

    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']

    get(
      '/fhir/r4/Patient/2',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['id']
  end

  test 'USER FLOW: epi enrollers should have access to all patients within jurisdiction' do
    @user = User.find_by(email: 'state1_epi_enroller@example.com')
    @user.update!(api_enabled: true, jurisdiction_id: 2)
    @user_patient_token_rw = Doorkeeper::AccessToken.create(resource_owner_id: @user.id, application: @user_patient_read_write_app, scopes: 'user/Patient.*')

    get(
      '/fhir/r4/Patient/1',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']

    get(
      '/fhir/r4/Patient/2',
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 2, json_response['id']
  end

  #----- create tests -----
  test 'SYSTEM FLOW: should create Patient via create' do
    patient = Patient.find_by(id: 1)
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    p = Patient.find_by(id: id)
    assert_not p.nil?
    h = History.where(patient_id: id)
    assert_not h.first.nil?
    assert_equal 1, h.count
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert response.headers['Location'].ends_with?(json_response['id'].to_s)
    assert_equal 'USA, State 1',
                 json_response['extension'].find { |e| e['url'] == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }['valueString']
    assert_equal "/fhir/r4/Patient/#{id}", json_response['contained'].first['target'].first['reference']
    assert_equal @system_patient_read_write_app.uid, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal @system_patient_read_write_app.name, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
    assert_equal patient.user_defined_id_statelocal, json_response['identifier'].find { |i| i['system'].include? 'state-local-id' }['value']
  end

  test 'USER FLOW: should create Patient via create' do
    patient = Patient.find_by(id: 1)
    post(
      '/fhir/r4/Patient', params: @patient_1.to_json,
                          headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    id = json_response['id']
    p = Patient.find_by(id: id)
    assert_not p.nil?
    h = History.where(patient_id: id)
    assert_not h.first.nil?
    assert_equal 1, h.count
    assert_equal 'state1_epi@example.com (API)', h.first.created_by
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 3, json_response['telecom'].count
    assert_equal 'Boehm62', json_response['name'].first['family']
    assert response.headers['Location'].ends_with?(json_response['id'].to_s)
    assert_equal 'USA, State 1',
                 json_response['extension'].find { |e| e['url'] == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }['valueString']
    assert_equal "/fhir/r4/Patient/#{id}", json_response['contained'].first['target'].first['reference']
    assert_equal Patient.find_by(id: id).creator_id, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal Patient.find_by(id: id).creator.email, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
  end

  test 'should calculate Patient age via create' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :created
    json_response = JSON.parse(response.body)
    patient = Patient.find(json_response['id'])
    assert_equal 25, patient.age
  end

  test 'should be unprocessable entity via create with validation errors' do
    patient = IO.read(file_fixture('fhir_invalid_patient.json'))
    json_patient = JSON.parse(patient)
    post(
      '/fhir/r4/Patient',
      params: patient,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 18, issues.length
    monitoring_plan_iss = issues.find { |e| /Invalid.*Monitoring Plan/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(monitoring_plan_iss['expression'].first, json_patient) == 'Invalid')
    state_iss = issues.find { |e| /Old York.*State/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(state_iss['expression'].first, json_patient) == 'Old York')
    eth_iss = issues.find { |e| /0000.*Ethnicity/.match(e['diagnostics']) }
    assert_not_nil eth_iss
    # FHIRPath lib errors on paths with nested extensions. The below assertion should work.
    # assert(FHIRPath.evaluate(eth_iss['expression'].first, json_patient) == '0000')
    pct_iss = issues.find { |e| /High noon.*Preferred Contact Time/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(pct_iss['expression'].first, json_patient) == 'High noon')
    sex_iss = issues.find { |e| /On FHIR.*Sex/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(sex_iss['expression'].first, json_patient) == 'On FHIR')
    phone_type_iss = issues.find { |e| /Dumbphone.*Telephone Type/.match(e['diagnostics']) }
    assert_not_nil phone_type_iss
    # FHIRPath lib errors on paths with nested extensions. The below assertion should work.
    # assert(FHIRPath.evaluate(phone_type_iss['expression'].first, json_patient) == 'Dumbphone')
    phone_iss = issues.find { |e| /123.*Primary Telephone/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(phone_iss['expression'].first, json_patient) == '123')
    dob_iss = issues.find { |e| /Date of Birth/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(dob_iss['expression'].first, json_patient) == '2000')
    lde_iss = issues.find { |e| /Last Date of Exposure/.match(e['diagnostics']) }
    assert_not_nil lde_iss # LDE is omitted from the request, so don't eval the FHIRPath
    sod_iss = issues.find { |e| /1492.*Symptom Onset/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(sod_iss['expression'].first, json_patient) == '1492')
    add_travel_start_date_iss = issues.find { |e| /1776.*Additional Planned Travel Start Date/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(add_travel_start_date_iss['expression'].first, json_patient) == '1776')
    dod_iss = issues.find { |e| /2020-01-32.*Date of Departure/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(dod_iss['expression'].first, json_patient) == '2020-01-32')
    doa_iss = issues.find { |e| /9999-99-99.*Date of Arrival/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(doa_iss['expression'].first, json_patient) == '9999-99-99')
    last_iss = issues.find { |e| /Last Name/.match(e['diagnostics']) }
    assert_not_nil last_iss # Last name is omitted from the request, so don't eval the FHIRPath
    assigned_usr_iss = issues.find { |e| /10000.*Assigned User/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(assigned_usr_iss['expression'].first, json_patient) == 1_000_000)
    email_iss = issues.find { |e| /Email.*Primary Contact Method/.match(e['diagnostics']) }
    assert_not_nil email_iss # Email is omitted from the request, so don't eval the FHIRPath
  end

  test 'should group Patients in households with matching phone numbers' do
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be a dependent in the same household as patient with ID 1, who is now the HoH
    assert_equal 1, Patient.find_by(id: json_response['id']).responder_id
  end

  test 'should group Patients in households with matching emails' do
    Patient.find_by(id: 1).update!(preferred_contact_method: 'E-mailed Web Link')
    @patient_1 = Patient.find_by(id: 1).as_fhir
    post(
      '/fhir/r4/Patient',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be a dependent in the same household as patient with ID 1, who is now the HoH
    assert_equal 1, Patient.find_by(id: json_response['id']).responder_id
  end

  test 'should make Patient a self reporter if no matching number or email' do
    post(
      '/fhir/r4/Patient',
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :created
    json_response = JSON.parse(response.body)
    # Should be their own reporter since they have a unique phone number and email
    assert_equal json_response['id'], Patient.find_by(id: json_response['id']).responder_id
  end

  #----- update tests -----

  test 'should update Patient via update' do
    patient_id = 1
    patient = Patient.find_by(id: 2)
    resource_path = "/fhir/r4/Patient/#{patient_id}"
    put(
      resource_path,
      params: @patient_2.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)
    assert_not p.nil?
    assert p.black_or_african_american
    assert p.asian
    assert_equal 'Patient', json_response['resourceType']
    assert_equal 'Kirlin44', json_response['name'].first['family']
    assert_equal 'SMS Texted Weblink', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' }.first['valueString']
    assert_equal 'Afternoon', json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' }.first['valueString']
    assert json_response['extension'].filter { |e| e['url'].include? 'continuous-exposure' }.first['valueBoolean']
    assert_equal 3.days.ago.strftime('%Y-%m-%d'), json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' }.first['valueDate']
    assert p.user_defined_symptom_onset
    assert json_response['extension'].filter { |e| e['url'].include? 'isolation' }.first['valueBoolean']
    assert_equal 'USA, State 1, County 1',
                 json_response['extension'].find { |e| e['url'] == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }['valueString']
    assert_equal resource_path, json_response['contained'].first['target'].first['reference']
    assert_equal Patient.find_by(id: patient_id).creator_id, json_response['contained'].first['agent'].first['who']['identifier']['value']
    assert_equal Patient.find_by(id: patient_id).creator.email, json_response['contained'].first['agent'].first['who']['display']
    assert_equal patient.primary_telephone_type, fhir_ext_str(json_response['telecom'].first, 'phone-type')
    assert_equal patient.secondary_telephone_type, fhir_ext_str(json_response['telecom'].second, 'phone-type')
    assert_equal patient.monitoring_plan, fhir_ext_str(json_response, 'monitoring-plan')
    assert_equal patient.assigned_user, fhir_ext_pos_int(json_response, 'assigned-user')
    assert_equal patient.additional_planned_travel_start_date.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'additional-planned-travel-start-date')
    assert_equal patient.port_of_origin, fhir_ext_str(json_response, 'port-of-origin')
    assert_equal patient.date_of_departure.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-departure')
    assert_equal patient.flight_or_vessel_number, fhir_ext_str(json_response, 'flight-or-vessel-number')
    assert_equal patient.flight_or_vessel_carrier, fhir_ext_str(json_response, 'flight-or-vessel-carrier')
    assert_equal patient.date_of_arrival.strftime('%Y-%m-%d'), fhir_ext_date(json_response, 'date-of-arrival')
    assert_equal patient.exposure_notes, fhir_ext_str(json_response, 'exposure-notes')
    assert_equal patient.travel_related_notes, fhir_ext_str(json_response, 'travel-related-notes')
    assert_equal patient.additional_planned_travel_related_notes, fhir_ext_str(json_response, 'additional-planned-travel-notes')
    assert_equal patient.user_defined_id_statelocal, json_response['identifier'].find { |i| i['system'].include? 'state-local-id' }['value']
  end

  test 'should create "Record Edit" and not "Monitoring Change" History item when updating patient with record edit' do
    patient = @patient_2
    patient.identifier = [FHIR::Identifier.new(system: 'http://saraalert.org/SaraAlert/state-local-id', value: '123')]
    resource_path = "/fhir/r4/Patient/#{patient.id}"
    histories = History.where(patient: patient.id)
    record_edit_count = histories.where(history_type: 'Record Edit')&.count || 0
    monitoring_change_count = histories.where(history_type: 'Monitoring Change')&.count || 0
    put(
      resource_path,
      params: patient.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    histories = History.where(patient: patient.id)
    assert_equal(record_edit_count + 1, histories.where(history_type: 'Record Edit').count)
    assert_equal(monitoring_change_count, histories.where(history_type: 'Monitoring Change').count)
    assert_match(/Changes were.*User defined id statelocal \("EX-904188" to "123"\)/, histories.find_by(history_type: 'Record Edit').comment)
  end

  test 'should create "Monitoring Change" History item when updating patient with monitoring change' do
    patient = @patient_2
    resource_path = "/fhir/r4/Patient/#{patient.id}"
    histories = History.where(patient: patient.id)
    monitoring_change_count = histories.where(history_type: 'Monitoring Change').count
    patch = [
      { 'op': 'replace', 'path': '/active', 'value': 'false' }
    ]
    patch(
      resource_path,
      params: patch.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/json-patch+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal false, json_response['active']
    histories = History.where(patient: patient.id)
    assert_equal(monitoring_change_count + 2, histories.where(history_type: 'Monitoring Change').count)
    assert_match(/Continuous Exposure/, histories.find_by(created_by: 'Sara Alert System').comment)
    assert_match(/"Monitoring" to "Not Monitoring"/, histories.find_by(history_type: 'Monitoring Change').comment)
  end

  test 'should update Patient via update and set omitted fields to nil ' do
    # Possible update request that omits all fields that can be updated except for the "active" field.
    patient_update = {
      'id' => @patient_2.id,
      'birthDate' => @patient_2.birthDate,
      'name' => @patient_2.name,
      'address' => @patient_2.address,
      'extension' => @patient_1.extension.find { |e| e.url.include? 'last-date-of-exposure' },
      'active' => false,
      'resourceType' => 'Patient'
    }

    put(
      '/fhir/r4/Patient/1',
      params: patient_update.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)

    assert_not p.nil?
    assert_equal 'Patient', json_response['resourceType']
    assert_equal([], json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-method' })
    assert_equal([], json_response['extension'].filter { |e| e['url'].include? 'preferred-contact-time' })
    assert_equal([], json_response['extension'].filter { |e| e['url'].include? 'symptom-onset-date' })
    assert_equal false, json_response['active']
  end

  test 'should properly close Patient record via update' do
    # Possible update request that omits many fields but sets active to false
    patient_update = {
      'id' => @patient_2.id,
      'birthDate' => @patient_2.birthDate,
      'name' => @patient_2.name,
      'address' => @patient_2.address,
      'extension' => @patient_1.extension.find { |e| e.url.include? 'last-date-of-exposure' },
      'active' => false,
      'resourceType' => 'Patient',
      'telecom' => [
        {
          "system": 'email',
          "value": '2966977816fake@example.com',
          "rank": 1
        }
      ]
    }

    put(
      '/fhir/r4/Patient/1',
      params: patient_update.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    p = Patient.find_by(id: 1)

    assert_not p.nil?

    # Record should be closed
    assert_not json_response['active']
    assert_not p.monitoring

    # Closed at date should have been set to today
    assert_equal DateTime.now.to_date, p.closed_at&.to_date
  end

  test 'should differentiate USA and Foreign addresses in update' do
    @patient_1.address << FHIR::Address.new(line: ['123 First Ave', 'Unit 22', 'Sector B'], city: 'Northland', state: 'Quebec', postalCode: '77658-0950',
                                            country: 'Canada')
    @patient_1.address[1].extension << FHIR::Extension.new(url: 'http://saraalert.org/StructureDefinition/address-type', valueString: 'Foreign')

    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :ok
    patient = Patient.find_by(id: 1)
    json_response = JSON.parse(response.body)
    # Test that the address was saved as expected
    assert_equal @patient_1.address[0].line[0], patient.address_line_1
    assert_equal @patient_1.address[0].city, patient.address_city
    assert_equal @patient_1.address[0].state, patient.address_state
    assert_equal @patient_1.address[0].postalCode, patient.address_zip
    assert_equal @patient_1.address[0].district, patient.address_county
    # Test that the foreign address was saved as expected
    assert_equal @patient_1.address[1].line[0], patient.foreign_address_line_1
    assert_equal @patient_1.address[1].line[1], patient.foreign_address_line_2
    assert_equal @patient_1.address[1].line[2], patient.foreign_address_line_3
    assert_equal @patient_1.address[1].city, patient.foreign_address_city
    assert_equal @patient_1.address[1].state, patient.foreign_address_state
    assert_equal @patient_1.address[1].postalCode, patient.foreign_address_zip
    assert_equal @patient_1.address[1].country, patient.foreign_address_country

    # Test that the response is as expected
    assert_equal JSON.parse(@patient_1.address.to_json), json_response['address']
  end

  test 'should update address fields from an explicit USA address' do
    @patient_1.address = [FHIR::Address.new(line: ['123 First Ave', 'Unit 22'], city: 'Southland', state: 'Vermont', postalCode: '77658-0950',
                                            district: 'Middletown')]
    @patient_1.address[0].extension << FHIR::Extension.new(url: 'http://saraalert.org/StructureDefinition/address-type', valueString: 'USA')

    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :ok
    patient = Patient.find_by(id: 1)
    json_response = JSON.parse(response.body)
    # Test that the address was saved as expected
    assert_equal @patient_1.address[0].line[0], patient.address_line_1
    assert_equal @patient_1.address[0].city, patient.address_city
    assert_equal @patient_1.address[0].state, patient.address_state
    assert_equal @patient_1.address[0].postalCode, patient.address_zip
    assert_equal @patient_1.address[0].district, patient.address_county

    # Test that the foreign address was not saved
    assert_nil patient.foreign_address_line_1
    assert_nil patient.foreign_address_line_2
    assert_nil patient.foreign_address_line_3
    assert_nil patient.foreign_address_city
    assert_nil patient.foreign_address_state
    assert_nil patient.foreign_address_zip
    assert_nil patient.foreign_address_country

    # Test that the response is as expected
    assert_equal @patient_1.address[0].line, json_response['address'][0]['line']
    assert_equal @patient_1.address[0].city, json_response['address'][0]['city']
    assert_equal @patient_1.address[0].state, json_response['address'][0]['state']
    assert_equal @patient_1.address[0].postalCode, json_response['address'][0]['postalCode']
  end

  test 'should ignore unknown address types in update' do
    @patient_1.address << FHIR::Address.new(line: ['123 First Ave', 'Unit 22', 'Sector B'], city: 'Northland', state: 'Quebec', postalCode: '77658-0950',
                                            country: 'Canada')
    @patient_1.address[1].extension << FHIR::Extension.new(url: 'http://saraalert.org/StructureDefinition/address-type', valueString: 'mysterious')

    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )

    assert_response :ok
    patient = Patient.find_by(id: 1)
    json_response = JSON.parse(response.body)
    # Test that the foreign address was not saved
    assert_nil patient.foreign_address_line_1
    assert_nil patient.foreign_address_line_2
    assert_nil patient.foreign_address_line_3
    assert_nil patient.foreign_address_city
    assert_nil patient.foreign_address_state
    assert_nil patient.foreign_address_zip
    assert_nil patient.foreign_address_country

    # Test that the address was saved as expected
    assert_equal @patient_1.address[0].line[0], patient.address_line_1
    assert_equal @patient_1.address[0].city, patient.address_city
    assert_equal @patient_1.address[0].state, patient.address_state
    assert_equal @patient_1.address[0].postalCode, patient.address_zip
    assert_equal @patient_1.address[0].district, patient.address_county

    # Test that the response is as expected
    assert_equal JSON.parse(@patient_1.address[0].to_json), json_response['address'][0]
    assert_nil json_response['address'][1]
  end

  test 'should be unprocessable entity via update with validation errors' do
    patient = IO.read(file_fixture('fhir_invalid_patient.json'))
    json_patient = JSON.parse(patient)
    put(
      '/fhir/r4/Patient/1',
      params: patient,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    issues = json_response['issue']

    assert_equal 18, issues.length
    monitoring_plan_iss = issues.find { |e| /Invalid.*Monitoring Plan/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(monitoring_plan_iss['expression'].first, json_patient) == 'Invalid')
    state_iss = issues.find { |e| /Old York.*State/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(state_iss['expression'].first, json_patient) == 'Old York')
    eth_iss = issues.find { |e| /0000.*Ethnicity/.match(e['diagnostics']) }
    assert_not_nil eth_iss
    # FHIRPath lib errors on paths with nested extensions. The below assertion should work.
    # assert(FHIRPath.evaluate(eth_iss['expression'].first, json_patient) == '0000')
    pct_iss = issues.find { |e| /High noon.*Preferred Contact Time/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(pct_iss['expression'].first, json_patient) == 'High noon')
    sex_iss = issues.find { |e| /On FHIR.*Sex/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(sex_iss['expression'].first, json_patient) == 'On FHIR')
    phone_type_iss = issues.find { |e| /Dumbphone.*Telephone Type/.match(e['diagnostics']) }
    assert_not_nil phone_type_iss
    # FHIRPath lib errors on paths with nested extensions. The below assertion should work.
    # assert(FHIRPath.evaluate(phone_type_iss['expression'].first, json_patient) == 'Dumbphone')
    phone_iss = issues.find { |e| /123.*Primary Telephone/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(phone_iss['expression'].first, json_patient) == '123')
    dob_iss = issues.find { |e| /Date of Birth/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(dob_iss['expression'].first, json_patient) == '2000')
    lde_iss = issues.find { |e| /Last Date of Exposure/.match(e['diagnostics']) }
    assert_not_nil lde_iss # LDE is omitted from the request, so don't eval the FHIRPath
    sod_iss = issues.find { |e| /1492.*Symptom Onset/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(sod_iss['expression'].first, json_patient) == '1492')
    add_travel_start_date_iss = issues.find { |e| /1776.*Additional Planned Travel Start Date/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(add_travel_start_date_iss['expression'].first, json_patient) == '1776')
    dod_iss = issues.find { |e| /2020-01-32.*Date of Departure/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(dod_iss['expression'].first, json_patient) == '2020-01-32')
    doa_iss = issues.find { |e| /9999-99-99.*Date of Arrival/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(doa_iss['expression'].first, json_patient) == '9999-99-99')
    last_iss = issues.find { |e| /Last Name/.match(e['diagnostics']) }
    assert_not_nil last_iss # Last name is omitted from the request, so don't eval the FHIRPath
    assigned_usr_iss = issues.find { |e| /10000.*Assigned User/.match(e['diagnostics']) }
    assert(FHIRPath.evaluate(assigned_usr_iss['expression'].first, json_patient) == 1_000_000)
    email_iss = issues.find { |e| /Email.*Primary Contact Method/.match(e['diagnostics']) }
    assert_not_nil email_iss # Email is omitted from the request, so don't eval the FHIRPath
  end

  test 'SYSTEM FLOW: should allow jurisdiction transfers when jurisdiction exists' do
    @patient_1.extension.find { |e| e.url == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }.valueString = 'USA, State 2'
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'USA, State 2', json_response['extension'].filter { |e| e['url'].include? 'full-assigned-jurisdiction-path' }.first['valueString']
    t = Transfer.find_by(patient_id: @patient_1.id)
    assert_equal Jurisdiction.find_by(path: 'USA, State 1').id, t.from_jurisdiction_id
    assert_equal Jurisdiction.find_by(path: 'USA, State 2').id, t.to_jurisdiction_id
    assert_equal @system_patient_read_write_app.user_id, t.who_id
  end

  test 'USER FLOW: should allow jurisdiction transfers when jurisdiction exists' do
    @patient_1.extension.find { |e| e.url == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }.valueString = 'USA, State 2'
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal 'USA, State 2', json_response['extension'].filter { |e| e['url'].include? 'full-assigned-jurisdiction-path' }.first['valueString']
    t = Transfer.find_by(patient_id: @patient_1.id)
    assert_equal Jurisdiction.find_by(path: 'USA, State 1').id, t.from_jurisdiction_id
    assert_equal Jurisdiction.find_by(path: 'USA, State 2').id, t.to_jurisdiction_id
    assert_equal @user.id, t.who_id
  end

  test 'SYSTEM FLOW: should be unprocessable entity via update with invalid jurisdiction path' do
    @patient_1.extension.find { |e| e.url == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }.valueString = 'USA'
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['issue'].length
    assert(json_response['issue'][0]['diagnostics'].include?('Jurisdiction does not exist'))
  end

  test 'USER FLOW: should be unprocessable entity via update with invalid jurisdiction path' do
    @patient_1.extension.find { |e| e.url == 'http://saraalert.org/StructureDefinition/full-assigned-jurisdiction-path' }.valueString = 'USA'
    put(
      '/fhir/r4/Patient/1',
      params: @patient_1.to_json,
      headers: { 'Authorization': "Bearer #{@user_patient_token_rw.token}", 'Content-Type': 'application/fhir+json' }
    )
    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['issue'].length
    assert(json_response['issue'][0]['diagnostics'].include?('Jurisdiction does not exist'))
  end

  test 'should update Patient via patch update' do
    patch = [
      { 'op': 'remove', 'path': '/communication/0/language' },
      { 'op': 'add', 'path': '/address/0/line/-', 'value': 'Unit 123' },
      { 'op': 'replace', 'path': '/name/0/family', 'value': 'Foo' }
    ]
    patch(
      '/fhir/r4/Patient/1',
      params: patch.to_json,
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Content-Type': 'application/json-patch+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 1, json_response['id']
    assert_nil json_response['communication']
    assert_equal 'Unit 123', json_response['address'][0]['line'][1]
    assert_equal 'Foo', json_response['name'][0]['family']
  end

  #----- search tests -----
  test 'should find Patient via search by _id' do
    get(
      '/fhir/r4/Patient?_id=1',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on existing family' do
    get(
      '/fhir/r4/Patient?family=Kirlin44',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find no Patients via search on non-existing family' do
    get(
      '/fhir/r4/Patient?family=foo',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 0, json_response['total']
  end

  test 'should find Patient via search on given' do
    get(
      '/fhir/r4/Patient?given=Chris32',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on telecom' do
    get(
      '/fhir/r4/Patient?telecom=5555550111',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 1, json_response['entry'].first['resource']['id']
  end

  test 'should find Patient via search on email' do
    get(
      '/fhir/r4/Patient?email=grazyna%40example.com',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 1, json_response['total']
    assert_equal 2, json_response['entry'].first['resource']['id']
  end

  test 'should get patients with default count via search' do
    get(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_equal 'http://www.example.com/fhir/r4/Patient?page=2', json_response['link'][0]['url']
  end

  test 'should get patients with count as 100 via search' do
    get(
      '/fhir/r4/Patient?_count=100',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end

  test 'should get Bundle via search without params' do
    get(
      '/fhir/r4/Patient',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    json_response['entry'].each do |entry|
      assert(entry['fullUrl'].include?('Patient') ||
              entry['fullUrl'].include?('Observation') ||
              entry['fullUrl'].include?('QuestionnaireResponse'))
    end
  end

  test 'should only get summary with count as 0 via search' do
    get(
      '/fhir/r4/Patient?_count=0',
      headers: { 'Authorization': "Bearer #{@system_patient_token_rw.token}", 'Accept': 'application/fhir+json' }
    )
    assert_response :ok
    json_response = JSON.parse(response.body)
    assert_equal 'Bundle', json_response['resourceType']
    assert_nil json_response['link']
  end
end
# rubocop:enable Metrics/ClassLength
