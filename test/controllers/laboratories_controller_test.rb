# frozen_string_literal: true

require 'test_case'

class LaboratoriesControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  # --- BEFORE ACTION --- #

  test 'before action: authenticate user' do
    post :create, params: {}
    assert_redirected_to(new_user_session_path)

    put :update, params: { id: 0 }
    assert_redirected_to(new_user_session_path)

    put :destroy, params: { id: 0 }
    assert_redirected_to(new_user_session_path)
  end

  test 'before action: check user can create' do
    user = create(:enroller_user)
    sign_in user

    post :create, params: {}
    assert_response(:forbidden)

    sign_out user
  end

  test 'before action: check user can edit' do
    user = create(:enroller_user)
    sign_in user

    put :update, params: { id: 'test' }
    assert_response(:forbidden)

    put :destroy, params: { id: 'test' }
    assert_response(:forbidden)

    sign_out user
  end

  test 'before action: check patient valid (patient exists)' do
    user = create(:public_health_enroller_user)
    sign_in user

    post :create, params: { patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Lab result cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :update, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Lab result cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :destroy, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Lab result cannot be modified for unknown monitoree with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'before action: check patient (current user can view patient)' do
    user = create(:public_health_enroller_user)
    user_2 = create(:public_health_enroller_user)
    patient = create(:patient, creator: user_2)
    sign_in user

    post :create, params: { patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    put :update, params: { id: 'test', patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    put :destroy, params: { id: 'test', patient_id: patient.id }
    assert_response(:forbidden)
    assert_equal("User does not have access to Patient with ID: #{patient.id}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'before action: check lab' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    sign_in user

    put :update, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)

    put :destroy, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)

    sign_out user
  end

  # --- CREATE --- #

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

  # --- UPDATE --- #

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

  test 'destroy: destroys laboratory and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    laboratory = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    delete_reason = 'Other'

    sign_in user
    put :destroy, params: {
      id: laboratory.id,
      patient_id: patient.id,
      delete_reason: delete_reason
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
