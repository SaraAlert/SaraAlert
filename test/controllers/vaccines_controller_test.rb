# frozen_string_literal: true

require 'test_case'

# IMPORTANT NOTE ON CHANGES TO Time.now CALLS IN THIS FILE
# Updated Time.now to Time.now.getlocal for Rails/TimeZone because Time.now defaulted to a zone. In this case it was the developer machine or CI/CD server zone.
class VaccinesControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  # --- BEFORE ACTION --- #

  test 'before action: authenticate user' do
    get :index
    assert_redirected_to(new_user_session_path)

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

  test 'before action: check vaccine' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    sign_in user

    put :update, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)
    assert_equal("Vaccination with ID #{'test'.to_i} cannot be found.", JSON.parse(response.body)['error'])

    put :destroy, params: { id: 'test', patient_id: patient.id }
    assert_response(:bad_request)
    assert_equal("Vaccination with ID #{'test'.to_i} cannot be found.", JSON.parse(response.body)['error'])

    sign_out user
  end

  # --- INDEX --- #

  test 'index: returns error if entries params cannot be validated' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    create(:vaccine, patient: patient)

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
    create(:vaccine, patient: patient)

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

  test 'index: redirects if patient has no vaccines' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user) # no vaccines
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
    vaccine = create(:vaccine, patient: patient)

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

    vaccines_relation = Vaccine.where(id: vaccine)
    validated_params = {
      patient_id: patient.id,
      search_text: '',
      sort_order: '',
      sort_direction: '',
      entries: 10,
      page: 0
    }
    returned_data = { table_data: vaccines_relation, total: vaccines_relation.size }

    # Stub the responses from the helper methods
    allow(@controller).to receive(:validate_vaccines_query).and_return(validated_params)
    allow(@controller).to receive(:search).and_return(vaccines_relation)
    allow(@controller).to receive(:sort).and_return(vaccines_relation)
    allow(@controller).to receive(:paginate).and_return(vaccines_relation.paginate(per_page: 10, page: 1))

    # NOTE: Must be called BEFORE the actual request is made as it is expecting it in the future
    # The .ordered here ensures these are called in this exact order.
    expect(@controller).to receive(:validate_vaccines_query).with(ActionController::Parameters.new(params.merge({ controller: 'vaccines',
                                                                                                                  action: 'index' }))).ordered
    expect(@controller).to receive(:search).with(vaccines_relation, params[:search]).ordered
    expect(@controller).to receive(:sort).with(vaccines_relation, '', '').ordered
    expect(@controller).to receive(:paginate).with(vaccines_relation, 10, 0).ordered

    get :index, params: params

    assert_response(:success)
    assert_equal(JSON.parse(returned_data.to_json), JSON.parse(response.body))
    sign_out user
  end

  # --- CREATE --- #

  test 'create: creates new vaccine and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    sign_in user
    group_name = Vaccine::VACCINE_STANDARDS.keys.sample
    product_name = Vaccine.product_name_options(group_name).sample
    administration_date = '2021-01-12'
    dose_number = 'Unknown'
    notes = 'Test notes'
    post :create, params: {
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: patient.id
    }

    assert_response(:success)
    assert_equal(1, patient.vaccines.count)
    assert_equal(1, patient.histories.count)

    vaccine = patient.vaccines.first
    assert_equal(group_name, vaccine[:group_name])
    assert_equal(product_name, vaccine[:product_name])
    assert_equal(administration_date.to_date, vaccine[:administration_date])
    assert_equal(dose_number, vaccine[:dose_number])
    assert_equal(notes, vaccine[:notes])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:vaccination], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User added a new vaccination (ID: #{vaccine.id}).", history[:comment])

    sign_out user
  end

  test 'create: handles failure on creation and returns error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    sign_in user
    group_name = Vaccine::VACCINE_STANDARDS.keys.sample
    product_name = 'test' # invalid product name
    administration_date = '2021-01-12'
    dose_number = 'Unknown'
    notes = 'Test notes'
    post :create, params: {
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: patient.id
    }

    assert_response(:bad_request)
    assert_equal("Vaccination was unable to be created. Errors: Value '#{product_name}' for 'Vaccine Product Name' is not an acceptable value," \
      " acceptable values for vaccine group #{group_name} are: '#{Vaccine.product_name_options(group_name).join("', '")}'", JSON.parse(response.body)['error'])
    assert_equal(0, patient.vaccines.count)
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  # --- UPDATE --- #

  test 'update: updates existing vaccine and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    vaccine = create(:vaccine, patient: patient, updated_at: 2.days.ago)

    sign_in user
    group_name = Vaccine::VACCINE_STANDARDS.keys.sample
    product_name = Vaccine.product_name_options(group_name).sample
    administration_date = '2021-01-12'
    dose_number = 'Unknown'
    notes = 'Test notes'
    put :update, params: {
      id: vaccine.id,
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: patient.id
    }

    vaccine.reload
    assert_response(:success)
    assert_in_delta(Time.now.getlocal, vaccine.updated_at, 1) # assert updated
    assert_equal(1, patient.histories.count)

    vaccine = Vaccine.find(vaccine.id)
    assert_equal(group_name, vaccine[:group_name])
    assert_equal(product_name, vaccine[:product_name])
    assert_equal(administration_date.to_date, vaccine[:administration_date])
    assert_equal(dose_number, vaccine[:dose_number])
    assert_equal(notes, vaccine[:notes])

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:vaccination_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal("User edited a vaccination (ID: #{vaccine.id}).", history[:comment])

    sign_out user
  end

  test 'update: handles failure on creation and returns error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    vaccine = create(:vaccine, patient: patient, updated_at: 2.days.ago)
    last_updated = vaccine.updated_at

    sign_in user
    group_name = Vaccine::VACCINE_STANDARDS.keys.sample
    product_name = 'test' # invalid product name
    administration_date = '2021-01-12'
    dose_number = 'Unknown'
    notes = 'Test notes'
    put :update, params: {
      id: vaccine.id,
      group_name: group_name,
      product_name: product_name,
      administration_date: administration_date,
      dose_number: dose_number,
      notes: notes,
      patient_id: patient.id
    }

    assert_response(:bad_request)
    assert_equal("Vaccination was unable to be updated. Errors: Value '#{product_name}' for 'Vaccine Product Name' is not an acceptable value," \
      " acceptable values for vaccine group #{group_name} are: '#{Vaccine.product_name_options(group_name).join("', '")}'", JSON.parse(response.body)['error'])
    assert_equal(last_updated, vaccine.updated_at) # assert not updated
    assert_equal(0, patient.histories.count)

    sign_out user
  end

  # --- DESTROY --- #

  test 'destroy: destroys existing vaccine and creates related history item' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    vaccine = create(:vaccine, patient: patient, updated_at: 2.days.ago)
    delete_reason = 'some delete reason'

    sign_in user
    put :destroy, params: {
      id: vaccine.id,
      patient_id: patient.id,
      delete_reason: delete_reason
    }

    assert_response(:success)
    assert_equal(0, patient.vaccines.count)
    assert_equal(1, patient.histories.count)

    assert_raises(ActiveRecord::RecordNotFound) do
      vaccine = Vaccine.find(vaccine.id)
    end

    history = patient.histories.first
    assert_equal(History::HISTORY_TYPES[:vaccination_edit], history[:history_type])
    assert_equal(user.email, history[:created_by])
    assert_equal(
      "User deleted a vaccine (ID: #{vaccine.id}, Vaccine Group: #{vaccine.group_name}, Product Name: #{vaccine.product_name}). Reason: #{delete_reason}.",
      history[:comment]
    )

    sign_out user
  end

  test 'destroy: handles failure on destroy and fires error' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    vaccine = create(:vaccine, patient: patient, updated_at: 2.days.ago)

    allow_any_instance_of(Vaccine).to receive(:destroy).and_return(false)
    sign_in user
    put :destroy, params: {
      id: vaccine.id,
      patient_id: patient.id,
      delete_reason: 'some delete reason'
    }

    assert_response(:bad_request)
    assert_equal('Vaccination was unable to be deleted.', JSON.parse(response.body)['error'])
    assert_equal(1, patient.vaccines.count)
    assert_equal(0, patient.histories.count)
    assert_equal(Vaccine.find(vaccine.id), vaccine)

    sign_out user
  end
end
