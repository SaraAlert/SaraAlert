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

  def success_create_report_test(role)
    ADMIN_OPTIONS['report_mode'] = false
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    threshold_hash = patients(:patient_1).jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash
    AssessmentReceipt.create(submission_token: patient_submission_token)
    user = create(role)
    sign_in user
    assert_no_difference 'AssessmentReceipt.count' do
      assert_difference 'Assessment.count', 1 do
        post :create, params: {
          patient_submission_token: patient_submission_token,
          unique_identifier: unique_identifier,
          experiencing_symptoms: 'yes',
          threshold_hash: threshold_hash,
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
      assert_equal 204, response.code.to_i
      sign_out user
    end
  end

  test 'successful create report as public_health_enroller_user' do
    success_create_report_test('public_health_enroller_user')
  end

  test 'successful create report as public_health_user' do
    success_create_report_test('public_health_user')
  end

  test 'successful create report as contact_tracer_user' do
    success_create_report_test('contact_tracer_user')
  end

  test 'successful create report as super_user' do
    success_create_report_test('super_user')
  end

  test 'redirected on bad update params' do
    post :update, params: {
      patient_submission_token: '',
      id: ''
    }
    assert_redirected_to :root
  end

  def unauthorized_user_create_report_test(role)
    ADMIN_OPTIONS['report_mode'] = false
    patient_submission_token = patients(:patient_1).submission_token
    unique_identifier = patients(:patient_1).jurisdiction.unique_identifier
    user = create(role)
    sign_in user
    assert_no_difference 'AssessmentReceipt.count' do
      assert_no_difference 'Assessment.count' do
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
      assert_redirected_to :root
      sign_out user
    end
  end

  test 'failed create report as enroller' do
    unauthorized_user_create_report_test('enroller_user')
  end

  test 'failed create report as analyst' do
    unauthorized_user_create_report_test('analyst_user')
  end

  test 'failed create report as admin' do
    unauthorized_user_create_report_test('admin_user')
  end

  def success_update_report_test(role)
    patient_submission_token = patients(:patient_1).submission_token
    assessment = assessments(:patient_1_assessment_2)

    # edit the assessment
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
          assert_equal 204, response.code.to_i
        end
      end
      assessment.reload
      assert_equal expected_change, assessment.reported_condition.symptoms.first.bool_value
    end
  end

  test 'successfully update report as public_health_user' do
    success_update_report_test('public_health_user')
  end

  test 'successfully update report as public_health_enroller_user' do
    success_update_report_test('public_health_enroller_user')
  end

  test 'successfully update report as contact_tracer_user' do
    success_update_report_test('contact_tracer_user')
  end

  test 'successfully update report as super_user' do
    success_update_report_test('super_user')
  end

  def unauthorized_user_update_report_test(role)
    patient_submission_token = patients(:patient_1).submission_token
    assessment = assessments(:patient_1_assessment_2)

    # edit the assessment
    user = create(role)
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    symptoms.first[:value] = !symptoms.first[:value]
    sign_in user
    assert_no_difference 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: patient_submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_redirected_to :root
        end
      end
      assessment.reload
      expected_value = assessments(:patient_1_assessment_2).reported_condition.symptoms.first.bool_value
      assert_equal expected_value, assessment.reported_condition.symptoms.first.bool_value
    end
  end

  test 'failed update report as enroller' do
    unauthorized_user_update_report_test('enroller_user')
  end

  test 'failed update report as analyst' do
    unauthorized_user_update_report_test('analyst_user')
  end

  test 'failed update report as admin' do
    unauthorized_user_update_report_test('admin_user')
  end

  test 'successfully update with old_submission_token as public_health_user' do
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
          assert_equal 204, response.code.to_i
          assert_match(/Symptom updates/, History.last.comment)
          assert_match(/Fever \("No" to "Yes"\)/, History.last.comment)
        end
      end
    end
    assessment.reload
    assert_equal expected_change, assessment.reported_condition.symptoms.first.bool_value
  end

  test 'updating with a new arbitrary bool symptom' do
    submission_token = patients(:patient_1).submission_token
    assessment = assessments(:patient_1_assessment_2)
    user = create(:public_health_user)
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    symptoms << {
      name: 'productive_cough',
      value: true,
      type: 'BoolSymptom',
      label: 'Productive Cough',
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
          assert_equal 204, response.code.to_i
        end
      end
    end
    assessment.reload

    assert_equal true, symptoms.find { |d| d[:name] == 'productive_cough' }[:value]

    # update the new symptom
    symptoms.find { |d| d[:name] == 'productive_cough' }[:value] = false
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_equal 204, response.code.to_i
          assert_match(/Symptom updates/, History.last.comment)
          assert_match(/Productive Cough \("Yes" to "No"\)/, History.last.comment)
        end
      end
    end
    assessment.reload
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    assert_equal false, symptoms.find { |d| d[:name] == 'productive_cough' }[:value]
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
          assert_equal 204, response.code.to_i
        end
      end
    end
    assessment.reload

    assert_equal 99.8, symptoms.find { |d| d[:name] == 'temperature' }[:value]

    # update the new symptom
    symptoms.find { |d| d[:name] == 'temperature' }[:value] = 100.4
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_equal 204, response.code.to_i
          assert_match(/Symptom updates/, History.last.comment)
          assert_match(/Temperature \("99.8" to "100.4"\)/, History.last.comment)
        end
      end
    end
    assessment.reload
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    assert_equal 100.4, symptoms.find { |d| d[:name] == 'temperature' }[:value]
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
          assert_equal 204, response.code.to_i
        end
      end
    end
    assessment.reload

    assert_equal 2, symptoms.find { |d| d[:name] == 'daysWithoutFever' }[:value]

    # update the new symptom
    symptoms.find { |d| d[:name] == 'daysWithoutFever' }[:value] = 3
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_equal 204, response.code.to_i
          assert_match(/Symptom updates/, History.last.comment)
          assert_match(/Days Without Fever \("2" to "3"\)/, History.last.comment)
        end
      end
    end
    assessment.reload
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    assert_equal 3, symptoms.find { |d| d[:name] == 'daysWithoutFever' }[:value]
  end

  test 'update boolean assessment with nils' do
    submission_token = patients(:patient_1).submission_token
    assessment = assessments(:patient_1_assessment_2)
    user = create(:public_health_user)
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    symptoms << {
      name: 'productive_cough',
      value: nil,
      type: 'BoolSymptom',
      label: 'Productive Cough',
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
          assert_equal 204, response.code.to_i
        end
      end
    end
    assessment.reload

    assert_nil symptoms.find { |d| d[:name] == 'productive_cough' }[:value]

    # update the new symptom
    symptoms.find { |d| d[:name] == 'productive_cough' }[:value] = false
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_equal 204, response.code.to_i
          assert_no_match(/Symptom updates/, History.last.comment)
          assert_no_match(/Productive Cough \("No" to "No"\)/, History.last.comment)
        end
      end
    end
    assessment.reload
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    assert_equal false, symptoms.find { |d| d[:name] == 'productive_cough' }[:value]

    # update the new symptom
    symptoms.find { |d| d[:name] == 'productive_cough' }[:value] = nil
    assert_changes 'History.count' do
      assert_no_difference 'AssessmentReceipt.count' do
        assert_no_difference 'Assessment.count' do
          post :update, params: {
            patient_submission_token: submission_token,
            id: assessment.id,
            experiencing_symptoms: 'yes',
            symptoms: symptoms
          }
          assert_equal 204, response.code.to_i
          assert_no_match(/Symptom updates/, History.last.comment)
          assert_no_match(/Productive Cough \("No" to "No"\)/, History.last.comment)
        end
      end
    end
    assessment.reload
    symptoms = symptoms_param(assessment.reported_condition.symptoms)
    assert_nil symptoms.find { |d| d[:name] == 'productive_cough' }[:value]
  end
end
