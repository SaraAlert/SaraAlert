# frozen_string_literal: true

require 'test_case'

class CloseContactsControllerTest < ActionController::TestCase
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

  test 'before action: check close_contact' do
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
    create(:close_contact, patient: patient)

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
    create(:close_contact, patient: patient)

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

  test 'index: redirects if patient has no close contacts' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user) # no close contacts
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
    cc = create(:close_contact, patient: patient)

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

    cc_relation = CloseContact.where(id: cc)
    validated_params = {
      patient_id: patient.id,
      search_text: '',
      sort_order: '',
      sort_direction: '',
      entries: 10,
      page: 0
    }
    returned_data = { table_data: cc_relation, total: cc_relation.size }

    # Stub the responses from the helper methods
    allow(@controller).to receive(:validate_close_contact_query).and_return(validated_params)
    allow(@controller).to receive(:search).and_return(cc_relation)
    allow(@controller).to receive(:sort).and_return(cc_relation)
    allow(@controller).to receive(:paginate).and_return(cc_relation.paginate(per_page: 10, page: 1))

    # NOTE: Must be called BEFORE the actual request is made as it is expecting it in the future
    # The .ordered here ensures these are called in this exact order.
    expect(@controller).to receive(:validate_close_contact_query).with(ActionController::Parameters.new(params.merge({ controller: 'close_contacts',
                                                                                                                       action: 'index' }))).ordered
    expect(@controller).to receive(:search).with(cc_relation, params[:search]).ordered
    expect(@controller).to receive(:sort).with(cc_relation, '', '').ordered
    expect(@controller).to receive(:paginate).with(cc_relation, 10, 0).ordered

    get :index, params: params

    assert_response(:success)
    assert_equal(JSON.parse(returned_data.to_json), JSON.parse(response.body))
    sign_out user
  end

  # --- CREATE --- #

  test 'create: creates new close contact and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    sign_in user
    first_name = 'test'
    last_name = 'test'
    email = 'email@test.com'
    post :create, params: {
      first_name: first_name,
      last_name: last_name,
      email: email,
      patient_id: patient.id
    }

    assert_response(:success)
    assert_equal(1, patient.close_contacts.count)
    assert_equal(1, patient.histories.count)

    close_contact = patient.close_contacts.first
    assert_equal(first_name, close_contact[:first_name])
    assert_equal(last_name, close_contact[:last_name])
    assert_equal(email, close_contact[:email])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:close_contact], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User added a new close contact (ID: #{close_contact.id}).", history[:comment])

    sign_out user
  end

  test 'create: handles failure on create and fires error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    allow_any_instance_of(CloseContact).to receive(:save).and_return(false)
    sign_in user

    first_name = 'test'
    last_name = 'test'
    email = 'email@test.com'
    post :create, params: {
      first_name: first_name,
      last_name: last_name,
      email: email,
      patient_id: patient.id
    }

    assert_response(:bad_request)
    assert_equal('Close Contact was unable to be created.', JSON.parse(response.body)['error'])
    assert_equal(0, patient.close_contacts.count)
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  # --- UPDATE --- #

  test 'update: updates existing close contact and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    close_contact = create(:close_contact, patient: patient, updated_at: 2.days.ago)

    sign_in user
    first_name = 'test'
    last_name = 'test'
    email = 'email@test.com'
    put :update, params: {
      id: close_contact.id,
      first_name: first_name,
      last_name: last_name,
      email: email,
      patient_id: patient.id
    }

    close_contact.reload
    assert_response(:success)
    assert_in_delta(Time.now.getlocal, close_contact.updated_at, 1) # assert updated
    assert_equal(1, patient.histories.count)

    close_contact = CloseContact.find(close_contact.id)
    assert_equal(first_name, close_contact[:first_name])
    assert_equal(last_name, close_contact[:last_name])
    assert_equal(email, close_contact[:email])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:close_contact_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User edited a close contact (ID: #{close_contact.id}).", history[:comment])

    sign_out user
  end

  test 'update: handles failure on update and fires error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    close_contact = create(:close_contact, patient: patient, updated_at: 2.days.ago)

    allow_any_instance_of(CloseContact).to receive(:update).and_return(false)
    sign_in user

    first_name = 'test'
    last_name = 'test'
    email = 'email@test.com'
    put :update, params: {
      id: close_contact.id,
      first_name: first_name,
      last_name: last_name,
      email: email,
      patient_id: patient.id
    }

    assert_response(:bad_request)
    assert_equal('Close Contact was unable to be updated.', JSON.parse(response.body)['error'])
    assert_equal(1, patient.close_contacts.count)
    assert_equal(0, patient.histories.count)
    assert_equal(CloseContact.find(close_contact.id), close_contact)

    sign_out user
  end

  # --- DESTROY --- #

  test 'destroy: destroys existing close contact and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    close_contact = create(:close_contact, patient: patient, first_name: 'test', last_name: 'test', updated_at: 2.days.ago)
    delete_reason = 'some delete reason'

    sign_in user
    put :destroy, params: {
      id: close_contact.id,
      patient_id: patient.id,
      delete_reason: delete_reason
    }

    assert_response(:success)
    assert_equal(1, patient.histories.count)

    assert_raises(ActiveRecord::RecordNotFound) do
      close_contact = CloseContact.find(close_contact.id)
    end

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:close_contact_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User deleted a close contact (ID: #{close_contact.id}, Name: #{close_contact.first_name} #{close_contact.last_name}, Enrolled: No"\
      "). Reason: #{delete_reason}.", history[:comment])

    sign_out user
  end

  test 'delete: handles failure on delete and fires error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    close_contact = create(:close_contact, patient: patient, updated_at: 2.days.ago)
    delete_reason = 'some delete reason'

    allow_any_instance_of(CloseContact).to receive(:destroy).and_return(false)
    sign_in user

    put :destroy, params: {
      id: close_contact.id,
      patient_id: patient.id,
      delete_reason: delete_reason
    }

    assert_response(:bad_request)
    assert_equal('Close Contact was unable to be deleted.', JSON.parse(response.body)['error'])
    assert_equal(1, patient.close_contacts.count)
    assert_equal(0, patient.histories.count)
    assert_equal(CloseContact.find(close_contact.id), close_contact)

    sign_out user
  end
end
