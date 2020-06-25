# frozen_string_literal: true

require 'test_case'

class PatientsControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  test 'before action authenticate user' do
    get :index
    assert_redirected_to(new_user_session_path)
  end

  test 'bulk update status' do
    %i[admin_user analyst_user].each do |role|
      user = create(role)
      sign_in user
      post :bulk_update_status
      assert_redirected_to @controller.root_url
      sign_out user
    end

    %i[enroller_user public_health_enroller_user public_health_user].each do |role|
      user = create(role)
      patient = create(:patient, creator: user)
      sign_in user

      error = assert_raises(ActionController::ParameterMissing) do
        post :bulk_update_status
      end
      assert_includes(error.message, 'ids')

      error = assert_raises(ActionController::ParameterMissing) do
        post :bulk_update_status, params: { ids: [] }
      end
      assert_includes(error.message, 'ids')

      error = assert_raises(ActionController::ParameterMissing) do
        post :bulk_update_status, params: { ids: [1] }
      end
      assert_includes(error.message, 'apply_to_group')

      not_found_id = Patient.last.id + 1

      # If apply_to_group is true: Patient.dependent_ids_for_patients
      error = assert_raises(ActiveRecord::RecordNotFound) do
        post :bulk_update_status, params: { ids: [not_found_id], apply_to_group: true }
      end
      assert_includes(error.message, "Couldn't find Patient with 'id'=#{not_found_id}")

      # If apply_to_group is false: current_user.get_patients
      error = assert_raises(ActiveRecord::RecordNotFound) do
        post :bulk_update_status, params: { ids: [not_found_id], apply_to_group: false }
      end
      assert_includes(error.message, "Couldn't find Patient with 'id'=#{not_found_id}")

      # Normal operation
      post :bulk_update_status, params: {
        ids: [patient.id],
        apply_to_group: false,
        patient: {
          monitoring: true,
          monitoring_reason: 'Meets Case Definition',
          public_health_action: '',
          isolation: true,
          case_status: 'Confirmed'
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
        post :bulk_update_status, params: {
          ids: [patient.id],
          apply_to_group: false,
          patient: {
            monitoring: true,
            monitoring_reason: 'Meets Case Definition',
            public_health_action: '',
            isolation: true,
            case_status: 'Confirmed'
          }
        }
        assert_response :success
      end

      # Apply to group logic
      post :bulk_update_status, params: {
        ids: [patient.id],
        apply_to_group: true,
        patient: {
          monitoring: true,
          monitoring_reason: 'Meets Case Definition',
          public_health_action: '',
          isolation: true,
          case_status: 'Confirmed'
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

      error = assert_raises(ActiveRecord::RecordNotFound) do
        post :bulk_update_status, params: {
          ids: [patient.id],
          apply_to_group: true,
          patient: {
            monitoring: true,
            monitoring_reason: 'Meets Case Definition',
            public_health_action: '',
            isolation: true,
            case_status: 'Confirmed'
          }
        }
      end
      assert_includes(error.message, 'spans multiple jurisidictions which you do not have access to.')

      sign_out user
    end
  end
end
