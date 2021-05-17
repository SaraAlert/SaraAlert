# frozen_string_literal: true

require 'test_case'

class LaboratoriesControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  test 'before action authenticate user' do
    post :create, params: {}
    assert_redirected_to(new_user_session_path)

    put :update, params: { id: 'test' }
    assert_redirected_to(new_user_session_path)
  end

  # --- CREATE --- #

  test 'create: redirects if current user cannot edit laboratories' do
    user = create(:enroller_user)
    patient = create(:patient, creator: user)

    sign_in user
    post :create, params: {
      lab_type: 'PCR',
      specimen_collection: '2021-01-11',
      report: '2021-01-12',
      result: 'negative',
      patient_id: patient.id
    }

    assert_redirected_to(@controller.root_url)
    assert_equal(0, patient.laboratories.count)
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  test 'create: creates new laboratory and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    sign_in user
    lab_type = 'PCR'
    specimen_collection = '2021-01-11'
    report = '2021-01-12'
    result = 'negative'
    post :create, params: {
      lab_type: lab_type,
      specimen_collection: specimen_collection,
      report: report,
      result: result,
      patient_id: patient.id
    }

    assert_response(:success)
    assert_equal(1, patient.laboratories.count)
    assert_equal(1, patient.histories.count)

    laboratory = patient.laboratories.first
    assert_equal(lab_type, laboratory[:lab_type])
    assert_equal(specimen_collection, laboratory[:specimen_collection].strftime('%F'))
    assert_equal(report.to_date, laboratory[:report])
    assert_equal(result, laboratory[:result])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:lab_result], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User added a new lab result (ID: #{laboratory.id}).", history[:comment])

    sign_out user
  end

  test 'create: checks for valid patient ID and returns error otherwise' do
    user = create(:public_health_enroller_user)
    history_count_before = History.count
    lab_count_before = Laboratory.count

    sign_in user
    post :create, params: {
      lab_type: 'PCR',
      specimen_collection: '2021-01-11',
      report: '2021-01-12',
      result: 'negative',
      patient_id: 'test'
    }

    assert_response(:bad_request)
    assert_equal("Lab Result cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])
    assert_equal(lab_count_before, Laboratory.count)
    assert_equal(history_count_before, History.count)

    sign_out user
  end

  test 'create: checks if user access to patient and returns error otherwise' do
    user = create(:public_health_enroller_user)
    patient = create(:patient) # patient has different creator

    history_count_before = History.count
    lab_count_before = Laboratory.count

    sign_in user
    post :create, params: {
      lab_type: 'PCR',
      specimen_collection: '2021-01-11',
      report: '2021-01-12',
      result: 'negative',
      patient_id: patient.id
    }

    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])
    assert_equal(lab_count_before, Laboratory.count)
    assert_equal(history_count_before, History.count)

    sign_out user
  end

  # --- UPDATE --- #

  test 'update: redirects if current user cannot edit laboratories' do
    user = create(:enroller_user)
    patient = create(:patient)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    last_updated = laboratory.updated_at

    sign_in user
    put :update, params: {
      id: laboratory.id,
      lab_type: 'PCR',
      specimen_collection: '2021-01-11',
      report: '2021-01-12',
      result: 'negative',
      patient_id: patient.id
    }

    assert_redirected_to(@controller.root_url)
    assert_equal(last_updated, laboratory.updated_at) # assert not updated
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  test 'update: checks if user access to patient and returns error otherwise' do
    user = create(:public_health_enroller_user)
    patient = create(:patient)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    last_updated = laboratory.updated_at

    history_count_before = History.count

    sign_in user
    put :update, params: {
      id: laboratory.id,
      lab_type: 'PCR',
      specimen_collection: '2021-01-11',
      report: '2021-01-12',
      result: 'negative',
      patient_id: patient.id
    }

    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])
    assert_equal(last_updated, laboratory.updated_at) # assert not updated
    assert_equal(history_count_before, History.count)

    sign_out user
  end

  test 'update: checks for valid patient ID and returns error otherwise' do
    user = create(:public_health_enroller_user)
    patient = create(:patient)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    last_updated = laboratory.updated_at

    sign_in user
    put :update, params: {
      id: laboratory.id,
      lab_type: 'PCR',
      specimen_collection: '2021-01-11',
      report: '2021-01-12',
      result: 'negative',
      patient_id: 'test'
    }

    assert_response(:bad_request)
    assert_equal("Lab Result cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])
    assert_equal(last_updated, laboratory.updated_at) # assert not updated
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  test 'update: updates new laboratory and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)

    sign_in user
    lab_type = 'PCR'
    specimen_collection = '2021-01-11'
    report = '2021-01-12'
    result = 'negative'
    put :update, params: {
      id: laboratory.id,
      lab_type: lab_type,
      specimen_collection: specimen_collection,
      report: report,
      result: result,
      patient_id: patient.id
    }

    laboratory.reload
    assert_response(:success)
    assert_in_delta(Time.now, laboratory.updated_at, 1) # assert updated
    assert_equal(1, patient.histories.count)

    laboratory = Laboratory.find(laboratory.id)
    assert_equal(lab_type, laboratory[:lab_type])
    assert_equal(specimen_collection, laboratory[:specimen_collection].strftime('%F'))
    assert_equal(report.to_date, laboratory[:report])
    assert_equal(result, laboratory[:result])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:lab_result_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User edited a lab result (ID: #{laboratory.id}).", history[:comment])

    sign_out user
  end

  # --- DESTROY --- #

  test 'destroy: redirects if current user cannot edit laboratories' do
    user = create(:enroller_user)
    patient = create(:patient)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    last_updated = laboratory.updated_at

    sign_in user
    put :destroy, params: {
      id: laboratory.id
    }

    assert_redirected_to(@controller.root_url)
    assert_equal(last_updated, laboratory.updated_at) # assert not updated
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  test 'destroy: checks if user access to patient and returns error otherwise' do
    user = create(:public_health_enroller_user)
    patient = create(:patient)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    last_updated = laboratory.updated_at

    history_count_before = History.count

    sign_in user
    put :destroy, params: {
      id: laboratory.id,
      patient_id: patient.id
    }

    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])
    assert_equal(last_updated, laboratory.updated_at) # assert not updated
    assert_equal(history_count_before, History.count)

    sign_out user
  end

  test 'destroy: checks for valid patient ID and returns error otherwise' do
    user = create(:public_health_enroller_user)
    patient = create(:patient)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    last_updated = laboratory.updated_at

    sign_in user
    put :destroy, params: {
      id: laboratory.id,
      patient_id: 'test'
    }

    assert_response(:bad_request)
    assert_equal("Lab Result cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])
    assert_equal(last_updated, laboratory.updated_at) # assert not updated
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  test 'destroy: destroys laboratory and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)

    delete_reason = 'Other'
    sign_in user
    put :destroy, params: {
      id: laboratory.id,
      delete_reason: delete_reason,
      patient_id: patient.id
    }

    assert_response(:success)
    assert_equal(1, patient.histories.count)

    assert_raises(ActiveRecord::RecordNotFound) do
      laboratory = Laboratory.find(laboratory.id)
    end

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:lab_result_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User deleted a lab result (ID: #{laboratory.id}). Reason: #{delete_reason}.", history[:comment])

    sign_out user
  end
end
