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

  test 'enrolling a patient sets the timezone correctly' do
    user = create(:public_health_enroller_user)
    sign_in user

    post :create, params: {
      patient: {
        jurisdicton_id: 1,
        monitoring: true,
        monitoring_plan: 'None',
        public_health_action: 'None',
        preferred_contact_method: 'Unknown',
        time_zone: 'America/New_York',
        first_name: 'test',
        last_name: 'test',
        date_of_birth: '2021-02-08',
        age: 0,
        address_line_1: '1234 Test Lane',
        address_city: 'Test Town',
        address_state: 'California',
        address_zip: '90210',
        continuous_exposure: false,
        last_date_of_exposure: '2021-01-31'
      }
    }
    assert_response :success
    patient = Patient.find(JSON.parse(response.body)['id'])
    assert_equal patient.time_zone, 'America/Los_Angeles'
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

  # ------- Household Updates -----

  test 'move_to_household successfully moves to household' do
    user = create(:public_health_enroller_user)
    desired_hoh = create(:patient, creator: user)
    dependent = create(:patient, creator: user)

    sign_in user

    post :move_to_household, params: {
      id: dependent.id,
      new_hoh_id: desired_hoh.id
    }

    assert_response :success
    assert desired_hoh.reload.head_of_household
    assert_not dependent.reload.head_of_household
    assert_equal(desired_hoh.id, desired_hoh.responder_id)
    assert_equal(desired_hoh.id, dependent.responder_id)

    # Verify history item was created for new HoH
    comment = "User added monitoree with ID #{dependent.id} to a household. This monitoree"\
              ' will now be responsible for handling the reporting on their behalf.'
    assert_equal(1, desired_hoh.histories.count)
    assert_equal(comment, desired_hoh.histories.last.comment)

    # Verify history item for was created for current patient being moved to a household
    comment = "User added monitoree to a household. Monitoree with ID #{desired_hoh.id} will now be responsible"\
              ' for handling the reporting on their behalf.'
    assert_equal(1, dependent.histories.count)
    assert_equal(comment, dependent.histories.last.comment)

    sign_out user
  end

  test 'move_to_household sends error message when new HoH is not accessible' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    sign_in user

    post :move_to_household, params: {
      id: patient.id,
      new_hoh_id: -9999
    }

    assert_response(:forbidden)
    assert_equal('Move to household action failed: selected Head of Household with ID -9999 is not accessible.',
                 JSON.parse(response.body)['error'])
    assert_not patient.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)

    sign_out user
  end

  test 'move_to_household sends error message when user does not have access to current record' do
    public_health_enroller_user = create(:public_health_enroller_user)
    enroller_user = create(:enroller_user)

    # Patient is not viewable by enroller user
    patient = create(:patient, creator: public_health_enroller_user)
    desired_hoh = create(:patient, creator: public_health_enroller_user)

    sign_in enroller_user

    post :move_to_household, params: {
      id: patient.id,
      new_hoh_id: desired_hoh.id
    }

    assert_response(:forbidden)
    assert_equal("Move to household action failed: selected Head of Household with ID #{desired_hoh.id} is not accessible.",
                 JSON.parse(response.body)['error'])
    assert_not patient.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)

    sign_out enroller_user
  end

  test 'move_to_household redirects when there is no change' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)
    sign_in user

    post :move_to_household, params: {
      id: patient.id,
      new_hoh_id: patient.id
    }

    assert_redirected_to(@controller.root_url)
    assert_not patient.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)
    sign_out user
  end

  test 'move_to_household sends error message when new head of household is a dependent' do
    user = create(:public_health_enroller_user)
    actual_hoh = create(:patient, creator: user)
    # Make desired Head of Household actually be a dependent
    desired_hoh = create(:patient, creator: user, responder_id: actual_hoh.id)
    patient = create(:patient, creator: user)

    sign_in user

    post :move_to_household, params: {
      id: patient.id,
      new_hoh_id: desired_hoh.id
    }

    assert_response(:bad_request)
    assert_equal('Move to household action failed: selected Head of Household is not valid as they are a dependent in an existing household. Please refresh.',
                 JSON.parse(response.body)['error'])
    assert_not patient.reload.head_of_household
    assert_not desired_hoh.reload.head_of_household
    assert actual_hoh.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)
    assert_equal(actual_hoh.id, desired_hoh.responder_id)
    assert_equal(actual_hoh.id, actual_hoh.responder_id)

    sign_out user
  end

  test 'move_to_household sends error message when record is already a HoH and is trying to assign a HoH' do
    user = create(:public_health_enroller_user)
    desired_hoh = create(:patient, creator: user)
    patient = create(:patient, creator: user)
    dependent = create(:patient, creator: user, responder_id: patient.id)

    sign_in user

    post :move_to_household, params: {
      id: patient.id,
      new_hoh_id: desired_hoh.id
    }

    assert_response(:bad_request)
    assert_equal(
      'Move to household action failed: monitoree is a head of household and therefore cannot be moved to a household through the Move to Household action. '\
      'Please refresh.',
      JSON.parse(response.body)['error']
    )
    assert patient.reload.head_of_household
    assert_not dependent.reload.head_of_household
    assert_not desired_hoh.reload.head_of_household
    assert_equal(patient.id, dependent.responder_id)
    assert_equal(patient.id, patient.responder_id)

    sign_out user
  end

  test 'move_to_household sends error message when record fails to update' do
    user = create(:public_health_enroller_user)
    desired_hoh = create(:patient, creator: user)
    patient = create(:patient, creator: user)

    # Create invalid record and skip validation
    patient.update_attribute('assigned_user', -1)
    patient.reload

    sign_in user

    post :move_to_household, params: {
      id: patient.id,
      new_hoh_id: desired_hoh.id
    }

    assert_response(:bad_request)
    assert_equal(
      'Move to household action failed: monitoree was unable to be be updated.',
      JSON.parse(response.body)['error']
    )
    assert_not patient.reload.head_of_household
    assert_not desired_hoh.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)
    assert_equal(desired_hoh.id, desired_hoh.responder_id)

    sign_out user
  end

  test 'remove_from_household successfully removes record from a household' do
    user = create(:public_health_enroller_user)
    hoh = create(:patient, creator: user)
    dependent = create(:patient, creator: user, responder_id: hoh.id)

    sign_in user

    post :remove_from_household, params: {
      id: dependent.id
    }

    assert_response :success
    assert_not hoh.reload.head_of_household
    assert_not dependent.reload.head_of_household
    assert_equal(dependent.id, dependent.responder_id)

    # Verify history item was created for old HoH
    comment = "User removed dependent monitoree with ID #{dependent.id} from the household. This monitoree"\
              ' will no longer be responsible for handling their reporting.'
    assert_equal(1, hoh.histories.count)
    assert_equal(comment, hoh.histories.last.comment)

    # Verify history item was created on current patient
    comment = "User removed monitoree from a household. Monitoree with ID #{hoh.id} will no longer be responsible for handling their reporting."
    assert_equal(1, dependent.histories.count)
    assert_equal(comment, dependent.histories.last.comment)

    sign_out user
  end

  test 'remove_from_household sends error message when user does not have access to current record' do
    public_health_enroller_user = create(:public_health_enroller_user)
    enroller_user = create(:enroller_user)

    # Patient is not viewable by enroller user
    patient = create(:patient, creator: public_health_enroller_user)

    sign_in enroller_user

    post :remove_from_household, params: {
      id: patient.id
    }

    assert_response(:forbidden)
    assert_equal('Remove from household action failed: user does not have permissions to update current monitoree.',
                 JSON.parse(response.body)['error'])
    assert_not patient.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)

    sign_out enroller_user
  end

  test 'remove_from_household sends error message when patient is a HoH' do
    user = create(:public_health_enroller_user)

    # Patient is not viewable by enroller user
    patient = create(:patient, creator: user)
    dependent = create(:patient, creator: user, responder_id: patient.id)

    sign_in user

    post :remove_from_household, params: {
      id: patient.id
    }

    assert_response(:bad_request)
    assert_equal('Remove from household action failed: monitoree is a head of household. Please refresh.',
                 JSON.parse(response.body)['error'])
    assert patient.reload.head_of_household
    assert_not dependent.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)
    assert_equal(patient.id, dependent.responder_id)

    sign_out user
  end

  test 'remove_from_household sends error message when record fails to update' do
    user = create(:public_health_enroller_user)
    hoh = create(:patient, creator: user)
    dependent = create(:patient, creator: user, responder_id: hoh.id)

    # Create invalid record and skip validation
    dependent.update_attribute('assigned_user', -1)
    dependent.reload

    sign_in user

    post :remove_from_household, params: {
      id: dependent.id
    }

    assert_response(:bad_request)
    assert_equal(
      'Remove from household action failed: monitoree was unable to be be updated.',
      JSON.parse(response.body)['error']
    )
    assert_not dependent.reload.head_of_household
    assert hoh.reload.head_of_household
    assert_equal(hoh.id, dependent.responder_id)
    assert_equal(hoh.id, hoh.responder_id)

    sign_out user
  end

  test 'update_hoh sends error message when new HoH is not accessible' do
    user = create(:public_health_enroller_user)
    patient = create(:patient, creator: user)

    sign_in user

    post :update_hoh, params: {
      id: patient.id,
      new_hoh_id: -9999
    }

    assert_response(:forbidden)
    assert_equal('Change head of household action failed: selected Head of Household with ID -9999 is not accessible.',
                 JSON.parse(response.body)['error'])
    assert_not patient.reload.head_of_household
    assert_equal(patient.id, patient.responder_id)

    sign_out user
  end

  test 'update_hoh sends error message when user does not have access to current record' do
    public_health_enroller_user = create(:public_health_enroller_user)
    enroller_user = create(:enroller_user)

    # Patient is not viewable by enroller user
    hoh = create(:patient, creator: public_health_enroller_user)
    dependent_1 = create(:patient, creator: enroller_user, responder_id: hoh.id)
    dependent_2 = create(:patient, creator: enroller_user, responder_id: hoh.id)

    sign_in enroller_user

    post :update_hoh, params: {
      id: hoh.id,
      new_hoh_id: dependent_2.id
    }

    assert_response(:forbidden)
    assert_equal('Change head of household action failed: user does not have permissions to update current monitoree or one or more of their dependents.',
                 JSON.parse(response.body)['error'])
    assert_not dependent_1.reload.head_of_household
    assert_not dependent_2.reload.head_of_household
    assert_equal(hoh.id, hoh.responder_id)

    sign_out enroller_user
  end

  test 'update_hoh sends error message when user does not have access to dependent record' do
    public_health_enroller_user = create(:public_health_enroller_user)
    enroller_user = create(:enroller_user)

    # Patient is not viewable by enroller user
    hoh = create(:patient, creator: enroller_user)
    dependent_1 = create(:patient, creator: public_health_enroller_user, responder_id: hoh.id)
    dependent_2 = create(:patient, creator: enroller_user, responder_id: hoh.id)

    sign_in enroller_user

    post :update_hoh, params: {
      id: hoh.id,
      new_hoh_id: dependent_2.id,
      household_ids: [dependent_1.id, dependent_2.id]
    }

    assert_response(:forbidden)
    assert_equal('Change head of household action failed: user does not have permissions to update current monitoree or one or more of their dependents.',
                 JSON.parse(response.body)['error'])
    assert_not dependent_1.reload.head_of_household
    assert_not dependent_2.reload.head_of_household
    assert_equal(hoh.id, hoh.responder_id)

    sign_out enroller_user
  end

  test 'update_hoh sends error message new HoH is not in household' do
    user = create(:public_health_enroller_user)
    hoh = create(:patient, creator: user)
    old_dependent = create(:patient, creator: user)
    dependent = create(:patient, creator: user, responder_id: hoh.id)

    sign_in user

    post :update_hoh, params: {
      id: hoh.id,
      new_hoh_id: old_dependent.id
    }

    assert_response(:bad_request)
    assert_equal('Change head of household action failed: selected Head of Household is no longer in household. Please refresh.',
                 JSON.parse(response.body)['error'])
    assert hoh.reload.head_of_household
    assert_not old_dependent.reload.head_of_household
    assert_not dependent.reload.head_of_household
    assert_equal(hoh.id, hoh.responder_id)
    assert_equal(hoh.id, dependent.responder_id)
    assert_equal(old_dependent.id, old_dependent.responder_id)

    sign_out user
  end

  test 'update_hoh successfully changes head of household with single dependent' do
    user = create(:public_health_enroller_user)
    hoh = create(:patient, creator: user)
    dependent = create(:patient, creator: user, responder_id: hoh.id)

    sign_in user

    post :update_hoh, params: {
      id: hoh.id,
      new_hoh_id: dependent.id
    }
    assert_response :success
    assert_not hoh.reload.head_of_household
    assert dependent.reload.head_of_household
    assert_equal(dependent.id, dependent.responder_id)
    assert_equal(dependent.id, hoh.responder_id)

    history_comment = "User changed head of household from monitoree with ID #{hoh.id} to monitoree with ID #{dependent.id}."\
                      " Monitoree with ID #{dependent.id} will now be responsible for handling the reporting for the household."

    # Verify history item was created for old HoH
    assert_equal(1, hoh.histories.count)
    assert_equal(history_comment, hoh.histories.last.comment)

    # Verify history item was created on new HoH
    assert_equal(1, dependent.histories.count)
    assert_equal(history_comment, dependent.histories.last.comment)

    sign_out user
  end

  test 'update_hoh successfully changes head of household with multiple dependents' do
    user = create(:public_health_enroller_user)
    hoh = create(:patient, creator: user)
    dependent_1 = create(:patient, creator: user, responder_id: hoh.id)
    dependent_2 = create(:patient, creator: user, responder_id: hoh.id)

    sign_in user

    post :update_hoh, params: {
      id: hoh.id,
      new_hoh_id: dependent_2.id
    }

    assert_response :success
    assert_not hoh.reload.head_of_household
    assert_not dependent_1.reload.head_of_household
    assert dependent_2.reload.head_of_household

    assert_equal(dependent_2.id, dependent_1.responder_id)
    assert_equal(dependent_2.id, hoh.responder_id)
    assert_equal(dependent_2.id, dependent_2.responder_id)

    history_comment = "User changed head of household from monitoree with ID #{hoh.id} to monitoree with ID #{dependent_2.id}."\
                      " Monitoree with ID #{dependent_2.id} will now be responsible for handling the reporting for the household."

    # Verify history item was created for old HoH
    assert_equal(1, hoh.histories.count)
    assert_equal(history_comment, hoh.histories.last.comment)

    # Verify history item was created on new HoH
    assert_equal(1, dependent_2.histories.count)
    assert_equal(history_comment, dependent_2.histories.last.comment)

    # Verify no history items for other dependents
    assert_equal(0, dependent_1.histories.count)

    sign_out user
  end

  test 'update_hoh sends error message when record(s) fail to update' do
    user = create(:public_health_enroller_user)
    hoh = create(:patient, creator: user)
    dependent = create(:patient, creator: user, responder_id: hoh.id)

    # Create invalid record and skip validation
    dependent.update_attribute('assigned_user', -1)
    dependent.reload

    sign_in user

    post :update_hoh, params: {
      id: hoh.id,
      new_hoh_id: dependent.id
    }

    assert_response(:bad_request)
    assert_equal(
      'Change head of household action failed: monitoree(s) were unable to be be updated.',
      JSON.parse(response.body)['error']
    )
    assert_not dependent.reload.head_of_household
    assert hoh.reload.head_of_household
    assert_equal(hoh.id, dependent.responder_id)
    assert_equal(hoh.id, hoh.responder_id)

    sign_out user
  end

  # ------- End Household Updates -----

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
      }, as: :json
      assert_response :success
      patient.reload
      assert(patient.monitoring)
      assert_equal(patient.monitoring_reason, 'Meets Case Definition')
      assert_equal(patient.public_health_action, '')
      assert(patient.isolation)
      assert_equal(patient.case_status, 'Confirmed')

      # Create a dependent patient created by the current user
      dependent = create(:patient, creator: user)
      patient.update(dependents: [patient, dependent])
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
        }, as: :json
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
      }, as: :json
      assert_response :success
      dependent.reload
      assert(dependent.monitoring)
      assert_equal(dependent.monitoring_reason, 'Meets Case Definition')
      assert_equal(dependent.public_health_action, '')
      assert(dependent.isolation)
      assert_equal(dependent.case_status, 'Confirmed')

      # Patient with dependent outside current user jurisdiction
      outside_dependent = create(:patient)
      patient.update(dependents: [patient, dependent, outside_dependent])
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
      }, as: :json
      assert_response 401
      body = JSON.parse(response.body)
      assert_includes(body['error'], 'spans jurisidictions which you do not have access to.')
      assert_equal(body['patients'].first['id'], patient.id)
      sign_out user
    end
  end

  test 'update status for a patient with no dependents' do
    user = create(:public_health_enroller_user)
    sign_in user
    patient = create(:patient, creator: user, monitoring: true, continuous_exposure: true)

    post :update_status, params: {
      id: patient.id,
      patient: { monitoring: false }
    }, as: :json

    assert_response :success
    patient.reload
    assert_not patient.monitoring
    assert_not_nil patient.closed_at
    assert_equal false, patient.continuous_exposure
    assert_match(/"Monitoring" to "Not Monitoring"/, History.find_by(patient: patient, created_by: user.email).comment)
    assert_match(/System turned off Continuous Exposure/, History.find_by(patient: patient, created_by: 'Sara Alert System').comment)
  end

  test 'update status for a patient with dependents and apply to household' do
    user = create(:public_health_enroller_user)
    sign_in user
    hoh_patient = create(:patient, creator: user, monitoring: true)
    dependent_patient = create(:patient, creator: user, monitoring: true)
    hoh_patient.dependents << dependent_patient

    post :update_status, params: {
      id: hoh_patient.id,
      apply_to_household: true,
      patient: { monitoring: false }
    }, as: :json

    assert_response :success
    hoh_patient.reload
    assert_not hoh_patient.monitoring
    dependent_patient.reload
    assert_not dependent_patient.monitoring
  end

  test 'update status for a patient with dependents and apply to continuous exposure household' do
    user = create(:public_health_enroller_user)
    sign_in user
    hoh_patient = create(:patient, creator: user, monitoring: true)
    dependent_patient = create(:patient, creator: user, monitoring: true)
    dependent_patient_ce = create(:patient, creator: user, monitoring: true, continuous_exposure: true)
    hoh_patient.dependents << [dependent_patient, dependent_patient_ce]

    post :update_status, params: {
      id: hoh_patient.id,
      apply_to_household_cm_only: true,
      patient: { monitoring: false }
    }, as: :json

    assert_response :success
    hoh_patient.reload
    assert_not hoh_patient.monitoring
    dependent_patient_ce.reload
    assert_not dependent_patient_ce.monitoring
    dependent_patient.reload
    assert dependent_patient.monitoring
  end

  test 'update status while ignoring fields not specified in diffState' do
    user = create(:public_health_enroller_user)
    sign_in user
    patient = create(:patient, creator: user, monitoring: true)

    post :update_status, params: {
      id: patient.id,
      patient: { monitoring: false },
      diffState: ['foo']
    }, as: :json

    assert_response :success
    patient.reload
    # Monitoring does not change, since it was not in diffState
    assert patient.monitoring

    post :update_status, params: {
      id: patient.id,
      patient: { monitoring: false },
      diffState: ['monitoring']
    }, as: :json

    assert_response :success
    patient.reload
    # Monitoring changes, since it was in diffState
    assert_not patient.monitoring
  end

  test 'update status when jurisdiction changes' do
    user = create(:public_health_enroller_user)
    sign_in user
    new_jurisdiction = create(:jurisdiction, path: 'Bar')
    patient = create(:patient, creator: user, monitoring: true)
    old_jurisdiction = patient.jurisdiction

    post :update_status, params: {
      id: patient.id,
      patient: { jurisdiction_id: new_jurisdiction.id }
    }, as: :json

    assert_response :success
    patient.reload
    assert_equal new_jurisdiction.id, patient.jurisdiction_id
    t = Transfer.find_by(patient_id: patient.id)
    assert_equal old_jurisdiction.id, t.from_jurisdiction_id
    assert_equal new_jurisdiction.id, t.to_jurisdiction_id
    assert_equal user.id, t.who_id
    assert_match(/blank to "Bar"/, History.find_by(patient: patient).comment)
  end

  test 'update resets symptom onset when isolation changes' do
    user = create(:public_health_enroller_user)
    sign_in user
    patient = create(:patient, symptom_onset: DateTime.now - 1.day, creator: user)
    created_at = DateTime.now.to_date - 2.day
    create(:assessment, patient_id: patient.id, symptomatic: true, created_at: created_at)

    post :update, params: {
      id: patient.id,
      propagated_fields: {},
      patient: {
        isolation: false,
        id: patient.id
      }
    }, as: :json

    assert_response :success
    patient.reload
    assert_equal created_at, patient.symptom_onset
    assert_not patient.user_defined_symptom_onset

    h = History.where(patient: patient)
    assert_match(/changed Symptom Onset Date/, h.second.comment)
  end
end
