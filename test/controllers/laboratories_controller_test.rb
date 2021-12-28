# frozen_string_literal: true

require 'test_case'

class LaboratoriesControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  # --- BEFORE ACTION --- #

  test 'before action: authenticate user' do
    post :create, params: {}
    assert_redirected_to(new_user_session_path)

    put :update, params: { id: 'test' }
    assert_redirected_to(new_user_session_path)

    put :destroy, params: { id: 'test' }
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
    assert_equal("Unknown patient with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :update, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Unknown patient with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

    put :destroy, params: { id: 'test', patient_id: 'test' }
    assert_response(:bad_request)
    assert_equal("Unknown patient with ID: #{'test'.to_i}", JSON.parse(response.body)['error'])

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

  # --- INDEX --- #

  test 'index: returns error if entries params cannot be validated' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    create(:laboratory, patient: patient)

    sign_in user

    params = {
      patient_id: patient.id,
      entries: -1, # invalid param
      page: 0,
      search: '',
      order: nil,
      direction: nil
    }

    get :index, params: params

    assert_response(:bad_request)
    assert_equal("Invalid Query (entries): #{params[:entries]}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'index: returns error if page params cannot be validated' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    create(:laboratory, patient: patient)

    sign_in user

    params = {
      patient_id: patient.id,
      entries: 5,
      page: -1, # invalid param
      search: '',
      order: nil,
      direction: nil
    }

    get :index, params: params

    assert_response(:bad_request)
    assert_equal("Invalid Query (page): #{params[:page]}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'index: returns bad_request if patient cannot be found' do
    user = create(:public_health_enroller_user)
    sign_in user

    mock_invalid_id = 'test'

    get :index, params: {
      patient_id: mock_invalid_id,
      entries: 10,
      page: 0,
      search: '',
      order: nil,
      direction: nil
    }

    assert_response(:bad_request)
    assert_equal("Unknown patient with ID: #{mock_invalid_id&.to_i}", JSON.parse(response.body)['error'])

    sign_out user
  end

  test 'index: redirects if patient has no labs' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user) # no labs
    sign_in user

    get :index, params: {
      patient_id: patient.id,
      entries: 10,
      page: 0,
      search: '',
      order: nil,
      direction: nil
    }
    assert_equal([], JSON.parse(response.body)['table_data'])
    assert_equal(0, JSON.parse(response.body)['total'])
    # assert_equal("Unknown patient with ID #{mock_invalid_id&.to_i}", JSON.parse(response.body)['error'])
    # assert_redirected_to(@controller.root_url)

    sign_out user
  end

  test 'index: calls necessary methods to fetch data' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    laboratory = create(:laboratory, patient: patient)

    sign_in user

    # Data is stringified as it would be in actual request
    params = {
      patient_id: patient.id.to_s,
      entries: '10',
      page: '0',
      search: '',
      order: '',
      direction: ''
    }

    labs_relation = Laboratory.where(id: laboratory)
    validated_params = {
      patient_id: patient.id,
      search_text: '',
      sort_order: '',
      sort_direction: '',
      entries: 10,
      page: 0
    }
    returned_data = { table_data: labs_relation, total: labs_relation.size }

    # Stub the responses from the helper methods
    allow(@controller).to receive(:validate_laboratory_query).and_return(validated_params)
    allow(@controller).to receive(:search).and_return(labs_relation)
    allow(@controller).to receive(:sort).and_return(labs_relation)
    allow(@controller).to receive(:paginate).and_return(labs_relation.paginate(per_page: 10, page: 1))

    # NOTE: Must be called BEFORE the actual request is made as it is expecting it in the future
    # The .ordered here ensures these are called in this exact order.
    expect(@controller).to receive(:validate_laboratory_query).with(ActionController::Parameters.new(params.merge({ controller: 'laboratories',
                                                                                                                    action: 'index' }))).ordered
    expect(@controller).to receive(:search).with(labs_relation, params[:search]).ordered
    expect(@controller).to receive(:sort).with(labs_relation, '', '').ordered
    expect(@controller).to receive(:paginate).with(labs_relation, 10, 0).ordered

    get :index, params: params

    assert_response(:success)
    assert_equal(JSON.parse(returned_data.to_json), JSON.parse(response.body))
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

  test 'create: handles failure on create and fires error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    allow_any_instance_of(Laboratory).to receive(:save).and_return(false)
    sign_in user

    lab_type = 'PCR'
    specimen_collection = '2021-01-11'
    report = '2021-01-12'
    result = 'negative'
    put :create, params: {
      lab_type: lab_type,
      specimen_collection: specimen_collection,
      report: report,
      result: result,
      patient_id: patient.id
    }

    assert_response(:bad_request)
    assert_equal('Lab result was unable to be created.', JSON.parse(response.body)['error'])
    assert_equal(0, patient.laboratories.count)
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  # --- UPDATE --- #

  test 'update: updates existing laboratory and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    lab = create(:laboratory, patient: patient, updated_at: 2.days.ago)

    sign_in user
    lab_type = 'PCR'
    specimen_collection = '2021-01-11'
    report = '2021-01-12'
    result = 'negative'
    put :update, params: {
      id: lab.id,
      lab_type: lab_type,
      specimen_collection: specimen_collection,
      report: report,
      result: result,
      patient_id: patient.id
    }

    lab.reload
    assert_response(:success)
    assert_in_delta(Time.now.getlocal, lab.updated_at, 1) # assert updated
    assert_equal(1, patient.histories.count)

    lab = Laboratory.find(lab.id)
    assert_equal(lab_type, lab[:lab_type])
    assert_equal(specimen_collection, lab[:specimen_collection].strftime('%F'))
    assert_equal(report.to_date, lab[:report])
    assert_equal(result, lab[:result])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:lab_result_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User edited a lab result (ID: #{lab.id}).", history[:comment])

    sign_out user
  end

  test 'update: handles failure on update and fires error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    lab = create(:laboratory, patient: patient, updated_at: 2.days.ago)

    allow_any_instance_of(Laboratory).to receive(:update).and_return(false)
    sign_in user

    lab_type = 'PCR'
    specimen_collection = '2021-01-11'
    report = '2021-01-12'
    result = 'negative'
    put :update, params: {
      id: lab.id,
      lab_type: lab_type,
      specimen_collection: specimen_collection,
      report: report,
      result: result,
      patient_id: patient.id
    }

    assert_response(:bad_request)
    assert_equal('Lab result was unable to be updated.', JSON.parse(response.body)['error'])
    assert_equal(1, patient.laboratories.count)
    assert_equal(0, patient.histories.count)
    assert_equal(Laboratory.find(lab.id), lab)

    sign_out user
  end

  # --- DESTROY --- #

  test 'destroy: destroys existing laboratory and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    lab = create(:laboratory, patient: patient, updated_at: 2.days.ago)
    delete_reason = 'some delete reason'

    sign_in user
    put :destroy, params: {
      id: lab.id,
      patient_id: patient.id,
      delete_reason: delete_reason
    }

    assert_response(:success)
    assert_equal(1, patient.histories.count)

    assert_raises(ActiveRecord::RecordNotFound) do
      lab = Laboratory.find(lab.id)
    end

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:lab_result_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User deleted a lab result (ID: #{lab.id}). Reason: #{delete_reason}.", history[:comment])

    sign_out user
  end

  test 'destroy: handles failure on destroy and fires error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    lab = create(:laboratory, patient: patient, updated_at: 2.days.ago)

    allow_any_instance_of(Laboratory).to receive(:destroy).and_return(false)
    sign_in user
    put :destroy, params: {
      id: lab.id,
      patient_id: patient.id,
      delete_reason: 'some delete reason'
    }

    assert_response(:bad_request)
    assert_equal('Lab result was unable to be deleted.', JSON.parse(response.body)['error'])
    assert_equal(1, patient.laboratories.count)
    assert_equal(0, patient.histories.count)
    assert_equal(Laboratory.find(lab.id), lab)

    sign_out user
  end
end
