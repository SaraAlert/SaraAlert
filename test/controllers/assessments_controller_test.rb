# frozen_string_literal: true

require 'test_case'

class AssessmentsControllerTest < ActionController::TestCase
  def setup; end

  def teardown; end

  def symptoms_param(model_symptoms)
    model_symptoms.map do |s|
      {
        name: s.name,
        value: s.value,
        type: s.type,
        label: s.label,
        notes: s.notes,
        required: s.required
      }
    end
  end

  test 'successful get new report as patient' do
    ADMIN_OPTIONS['report_mode'] = true
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    get :new, params: {
      patient_submission_token: patient_submission_token,
      unique_identifier: unique_identifier
    }
    assert_response :success
  end

  test 'successful get using old_unique_identifier as patient' do
    ADMIN_OPTIONS['report_mode'] = true
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = JurisdictionLookup.find_by(
      new_unique_identifier: patients(:patient_1).jurisdiction.unique_identifier
    ).old_unique_identifier
    get :new, params: {
      patient_submission_token: patient_submission_token,
      unique_identifier: unique_identifier
    }
    assert_response :success
  end

  test 'successful get new report as user' do
    ADMIN_OPTIONS['report_mode'] = false
    user = create(:public_health_enroller_user)
    sign_in user
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    get :new, params: {
      patient_submission_token: patient_submission_token,
      unique_identifier: unique_identifier
    }
    assert_response :success
  end

  test 'successful create report as patient' do
    ADMIN_OPTIONS['report_mode'] = true
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    assert_difference ['AssessmentReceipt.count'], 1 do
      post :create, params: {
        patient_submission_token: patient_submission_token,
        unique_identifier: unique_identifier,
        experiencing_symptoms: 'yes'
      }
    end
    assert_response :success
  end

  test 'hit limit number of reports per time period as patient' do
    ADMIN_OPTIONS['report_mode'] = true
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    assert_difference ['AssessmentReceipt.count'], 1 do
      post :create, params: {
        patient_submission_token: patient_submission_token,
        unique_identifier: unique_identifier,
        experiencing_symptoms: 'yes'
      }
    end
    assert_response :success
    get :new, params: {
      patient_submission_token: patient_submission_token,
      unique_identifier: unique_identifier
    }
    assert_redirected_to :already_reported_report
  end

  test 'successful create report as user' do
    ADMIN_OPTIONS['report_mode'] = false
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    AssessmentReceipt.create(submission_token: patient_submission_token)
    %i[public_health_enroller_user public_health_user contact_tracer_user super_user].each do |role|
      user = create(role)
      sign_in user
      assert_no_difference 'AssessmentReceipt.count' do
        assert_difference 'Assessment.count', 1 do
          post :create, params: {
            patient_submission_token: patient_submission_token,
            unique_identifier: unique_identifier,
            experiencing_symptoms: 'yes',
            symptoms: [
              {
                name: 'Cough',
                value: false,
                type: 'BoolSymptom',
                label: 'Cough',
                notes: 'Have you coughed today?'
              }
            ]
          }
        end
      end
      assert_redirected_to :patient_assessments
      sign_out user
    end
  end

  test 'redirected on bad update params' do
    post :update, params: {
      patient_submission_token: '',
      id: ''
    }
    assert_redirected_to :root
  end

  test 'redirected on ' do
  end

  test 'successfuly update report as user' do
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    assessment = assessments(:patient_1_assessment_2)

    # edit the assessment
    %i[public_health_user public_health_enroller_user contact_tracer_user super_user].each do |role|
      user = create(role)
      symptoms = symptoms_param(assessment.reported_condition.symptoms)
      expected_change = !symptoms.first[:value]
      symptoms.first[:value] = expected_change
      sign_in user
      assert_changes 'History.count' do
        assert_no_difference 'AssessmentReceipt.count' do
          assert_no_difference 'Assessment.count' do
            post :update, params: {
              patient_submission_token: patient_submission_token,
              id: assessment.id,
              experiencing_symptoms: 'yes',
              symptoms: symptoms
            }
            assert_redirected_to :patient_assessments
          end
        end
      end
      assessment.reload
      assert_equal expected_change, assessment.reported_condition.symptoms.first.bool_value
    end
  end

  test 'successfuly update with old_submission_token' do
    submission_token = patients(:patient_1).submission_token
    old_submission_token = PatientLookup.find_by(new_submission_token: submission_token).old_submission_token
    assessment = assessments(:patient_1_assessment_2)
    user = create(:public_health_user)
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    expected_change = !symptoms.first[:value]
    symptoms.first[:value] = expected_change
    sign_in user
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: old_submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_redirected_to :patient_assessments
        end
      end
    end
    assessment.reload
    assert_equal expected_change, assessment.reported_condition.symptoms.first.bool_value
  end

  test 'updating with a new arbitrary float symptom' do
    submission_token = patients(:patient_1).submission_token
    assessment = assessments(:patient_1_assessment_2)
    user = create(:public_health_user)
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    symptoms << {
      name: 'temperature',
      value: 99.8,
      type: 'FloatSymptom',
      label: 'Temperature',
      notes: nil,
      required: false
    }
    sign_in user

    # create the new symptom
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_redirected_to :patient_assessments
        end
      end
    end
    assessment.reload

    assert_equal 99.8, symptoms.find{|d| d[:name] == 'temperature'}[:value]

    # update the new symptom
    symptoms.find{|d| d[:name] == 'temperature'}[:value] = 100.4
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_redirected_to :patient_assessments
        end
      end
    end
    assessment.reload
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    assert_equal 100.4, symptoms.find{|d| d[:name] == 'temperature'}[:value]
  end

  test 'updating with a new arbitrary integer symptom' do
    submission_token = patients(:patient_1).submission_token
    assessment = assessments(:patient_1_assessment_2)
    user = create(:public_health_user)
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    symptoms << {
      name: 'daysWithoutFever',
      value: 2,
      type: 'IntegerSymptom',
      label: 'Days Without Fever',
      notes: nil,
      required: false
    }
    sign_in user

    # create the new symptom
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_redirected_to :patient_assessments
        end
      end
    end
    assessment.reload

    assert_equal 2, symptoms.find{|d| d[:name] == 'daysWithoutFever'}[:value]

    # update the new symptom
    symptoms.find{|d| d[:name] == 'daysWithoutFever'}[:value] = 3
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_redirected_to :patient_assessments
        end
      end
    end
    assessment.reload
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    assert_equal 3, symptoms.find{|d| d[:name] == 'daysWithoutFever'}[:value]
  end

  # test 'succesful get landing' do
  #   ADMIN_OPTIONS['report_mode'] = true
  #   get :landing
  #   assert_response :success
  # end
end
