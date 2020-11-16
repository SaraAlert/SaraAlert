# frozen_string_literal: true

require 'test_case'

class PatientsControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  test 'before action authenticate user' do
    get :index
    assert_redirected_to(new_user_session_path)
  end

  test 'head of household when creating a patient no matching contact info' do
    user = create(:public_health_enroller_user)
    sign_in user

    post :create, params: {
      patient: {
        first_name: 'test',
        last_name: 'test'
      }
    }
    assert_response :success
    body = JSON.parse(response.body)
    patient = Patient.find(body['id'])
    assert_not patient.head_of_household
    assert patient.responder.id == patient.id
    assert patient.self_reporter_or_proxy?
  end

  test 'head of household when creating a patient matching contact info email' do
    user = create(:public_health_enroller_user)
    head_of_household = create(:patient, creator: user, email: 'test@example.com')
    sign_in user

    post :create, params: {
      patient: {
        first_name: 'test',
        last_name: 'test',
        email: 'test@example.com',
        preferred_contact_method: 'E-mailed Web Link'
      }
    }
    assert_response :success
    body = JSON.parse(response.body)
    patient = Patient.find(body['id'])
    assert_not patient.head_of_household
    assert head_of_household.reload.head_of_household
  end

  test 'head of household when creating a patient matching contact info telephone' do
    user = create(:public_health_enroller_user)
    head_of_household = create(:patient, creator: user, primary_telephone: '555-555-5555')
    sign_in user

    post :create, params: {
      patient: {
        first_name: 'test',
        last_name: 'test',
        primary_telephone: '555-555-5555',
        preferred_contact_method: 'SMS Texted Weblink'
      }
    }
    assert_response :success
    body = JSON.parse(response.body)
    patient = Patient.find(body['id'])
    assert_not patient.head_of_household
    assert head_of_household.reload.head_of_household
  end

  test 'head of household when creating a patient explicit responder id' do
    user = create(:public_health_enroller_user)
    head_of_household = create(:patient, creator: user)

    sign_in user

    post :create, params: {
      patient: {
        first_name: 'test',
        last_name: 'test'
      },
      responder_id: head_of_household.id
    }

    assert_response :success
    body = JSON.parse(response.body)
    patient = Patient.find(body['id'])
    assert_not patient.reload.head_of_household
    assert head_of_household.reload.head_of_household
  end

  test 'head of household updates when head_of_household route' do
    user = create(:public_health_enroller_user)
    head_of_household = create(:patient, creator: user)
    sign_in user

    dependent = create(:patient, creator: user)

    post :update_hoh, params: {
      id: dependent.id,
      new_hoh_id: head_of_household.id
    }
    assert_response :success

    assert head_of_household.reload.head_of_household
    assert_not dependent.reload.head_of_household
  end

  test 'bulk update status' do
    %i[admin_user analyst_user].each do |role|
      user = create(role)
      sign_in user
      post :bulk_update
      assert_redirected_to @controller.root_url
      sign_out user
    end

    # public_health_enroller_user public_health_user
    %i[enroller_user].each do |role|
      user = create(role)
      patient = create(:patient, creator: user)
      sign_in user

      error = assert_raises(ActionController::ParameterMissing) do
        post :bulk_update
      end
      assert_includes(error.message, 'ids')

      error = assert_raises(ActionController::ParameterMissing) do
        post :bulk_update, params: { ids: [] }
      end
      assert_includes(error.message, 'ids')

      error = assert_raises(ActionController::ParameterMissing) do
        post :bulk_update, params: { ids: [1] }
      end
      assert_includes(error.message, 'apply_to_household')

      not_found_id = Patient.last.id + 1

      # If apply_to_household is true: Patient.dependent_ids_for_patients
      post :bulk_update, params: { ids: [not_found_id], apply_to_household: true }
      assert_redirected_to('/errors#not_found')

      # If apply_to_household is false: current_user.get_patients
      post :bulk_update, params: { ids: [not_found_id], apply_to_household: false }
      assert_redirected_to('/errors#not_found')

      # Normal operation
      post :bulk_update, params: {
        ids: [patient.id],
        apply_to_household: false,
        patient: {
          monitoring: true,
          monitoring_reason: 'Meets Case Definition',
          public_health_action: '',
          isolation: true,
          case_status: 'Confirmed',
          assigned_user: 50
        }
      }
      assert_response :success
      patient.reload
      assert(patient.monitoring)
      assert_equal(patient.monitoring_reason, 'Meets Case Definition')
      assert_equal(patient.public_health_action, '')
      assert(patient.isolation)
      assert_equal(patient.case_status, 'Confirmed')

      # Create a dependent patient created by the current user
      dependent = create(:patient, creator: user)
      patient.update(dependents: [dependent])
      dependent.update(responder: patient)

      # Apply to group logic
      assert_no_changes('dependent.updated_at') do
        post :bulk_update, params: {
          ids: [patient.id],
          apply_to_household: false,
          patient: {
            monitoring: true,
            monitoring_reason: 'Meets Case Definition',
            public_health_action: '',
            isolation: true,
            case_status: 'Confirmed',
            assigned_user: 50
          }
        }
        assert_response :success
      end

      # Apply to group logic
      post :bulk_update, params: {
        ids: [patient.id],
        apply_to_household: true,
        patient: {
          monitoring: true,
          monitoring_reason: 'Meets Case Definition',
          public_health_action: '',
          isolation: true,
          case_status: 'Confirmed',
          assigned_user: 50
        }
      }
      assert_response :success
      dependent.reload
      assert(dependent.monitoring)
      assert_equal(dependent.monitoring_reason, 'Meets Case Definition')
      assert_equal(dependent.public_health_action, '')
      assert(dependent.isolation)
      assert_equal(dependent.case_status, 'Confirmed')

      # Patient with dependent outside current user jurisdiction
      outside_dependent = create(:patient)
      patient.update(dependents: [dependent, outside_dependent])
      outside_dependent.update(responder: patient)

      post :bulk_update, params: {
        ids: [patient.id],
        apply_to_household: true,
        patient: {
          monitoring: true,
          monitoring_reason: 'Meets Case Definition',
          public_health_action: '',
          isolation: true,
          case_status: 'Confirmed',
          assigned_user: 50
        }
      }
      assert_response 401
      body = JSON.parse(response.body)
      assert_includes(body['error'], 'spans jurisidictions which you do not have access to.')
      assert_equal(body['patients'].first['id'], patient.id)
      sign_out user
    end
  end
end
