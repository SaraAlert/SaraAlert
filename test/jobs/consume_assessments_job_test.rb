# frozen_string_literal: true

require 'test_case'
require_relative '../test_helpers/consume_assessments_job_test_helper'

class ConsumeAssessmentsJobTest < ActiveJob::TestCase
  def setup
    @patient = create(:patient, submission_token: SecureRandom.hex(20), primary_telephone: '(555) 555-0111')
    @assessment_generator = ConsumeAssessmentsJobTestHelper::AssessmentGenerator.new(@patient)
  end

  def teardown; end

  test 'consume assessment bad json' do
    # There are no other side effects to test except examining the logger.
    expect_any_instance_of(ActiveSupport::Logger).to(receive(:error).with('ConsumeAssessmentsJob: Skipping invalid message.'))
    ConsumeAssessmentsJob.perform_async('not json')
  end

  test 'consume assessment valid json with wrong fields' do
    # There are no other side effects to test except examining the logger.
    expect_any_instance_of(ActiveSupport::Logger).to(receive(:info).with('ConsumeAssessmentsJob: No valid fields found in message. Skipping.'))
    ConsumeAssessmentsJob.perform_async('{"key": 0}')
  end

  ConsumeAssessmentsJobTestHelper::AssessmentGenerator.response_statuses.each do |response_status|
    test "response status #{response_status}" do
      @patient.update(last_assessment_reminder_sent: 1.day.ago)
      assert_difference '@patient.histories.count', 1 do
        ConsumeAssessmentsJob.perform_async(@assessment_generator.no_answer_assessment(response_status))
        @patient.reload
        assert_equal 'Contact Attempt', @patient.histories.first.history_type
        assert_includes @patient.histories.first.comment, @patient.primary_telephone
      end
    end

    test "#{response_status} contact attempt history for dependents" do
      dependent = create(:patient)
      dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))
      assert_difference 'dependent.histories.count', 1 do
        ConsumeAssessmentsJob.perform_async(@assessment_generator.no_answer_assessment(response_status))
        dependent.reload
        assert_equal 'Contact Attempt', dependent.histories.first.history_type
        assert_includes dependent.histories.first.comment.gsub(/\s{2,}/, ' '), 'head of household'
      end
    end
  end

  test 'consume assessment for a patient that has submitted recently' do
    # reporting limit defaults to 15 minutes
    @patient.update(assessments: [create(:assessment, patient: @patient)])
    latest_assessment = @patient.latest_assessment_at
    ConsumeAssessmentsJob.perform_async(@assessment_generator.generic_assessment(symptomatic: false))
    @patient.reload
    assert_equal latest_assessment, @patient.latest_assessment_at
  end

  test 'consume assessment patient not found by submission token' do
    assessment = @assessment_generator.invalid_submission_token
    parsed_assessment = JSON.parse(assessment)
    message = "ConsumeAssessmentsJob: No patient found with submission_token: #{parsed_assessment['patient_submission_token']}"
    # There are no other side effects to test except examining the logger.
    expect_any_instance_of(ActiveSupport::Logger).to(receive(:info).with(message))
    ConsumeAssessmentsJob.perform_async(assessment)
  end

  test 'consume assessment no threshold condition' do
    assessment = @assessment_generator.missing_threshold_condition
    parsed_assessment = JSON.parse(assessment)
    message = 'ConsumeAssessmentsJob: No ThresholdCondition found' \
    " (patient: #{@assessment_generator.patient.id}, threshold_condition_hash: #{parsed_assessment['threshold_condition_hash']})"
    # There are no other side effects to test except examining the logger.
    expect_any_instance_of(ActiveSupport::Logger).to(receive(:info).with(message))
    ConsumeAssessmentsJob.perform_async(assessment)
  end

  test 'consume assessment with reported symptoms' do
    assert_difference '@patient.assessments.count', 1 do
      ConsumeAssessmentsJob.perform_async(@assessment_generator.reported_symptom_assessment)
    end
  end

  test 'consume assessment with experiencing symptoms' do
    assert_difference '@patient.assessments.count', 1 do
      # Force experiencing_symptoms to true
      ConsumeAssessmentsJob.perform_async(@assessment_generator.reported_symptom_assessment(symptomatic: true))
      @patient.reload
      assert @patient.assessments.first.symptomatic
    end
  end

  test 'consume generic assessment symptomatic' do
    assert_difference '@patient.assessments.count', 1 do
      ConsumeAssessmentsJob.perform_async(@assessment_generator.generic_assessment(symptomatic: true))
      @patient.reload
      assert @patient.assessments.first.symptomatic
      assert_equal 'Monitoree', @patient.assessments.first.who_reported
    end

    # Bypass latest assessment check
    @patient.update(assessments: [])

    assert_difference '@patient.assessments.count', 1 do
      ConsumeAssessmentsJob.perform_async(@assessment_generator.generic_assessment(symptomatic: false))
      @patient.reload
      assert_not @patient.assessments.first.symptomatic
      assert_equal 'Monitoree', @patient.assessments.first.who_reported
    end
  end

  test 'consume generic assessment with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))
    assert_difference 'dependent.assessments.count', 1 do
      ConsumeAssessmentsJob.perform_async(@assessment_generator.generic_assessment(symptomatic: true))
      dependent.reload
      assert dependent.assessments.first.symptomatic
      assert_equal 'Proxy', dependent.assessments.first.who_reported
    end
  end

  test 'consume errored sms assessment' do
    @patient.update(preferred_contact_method: 'SMS Texted Weblink')
    assert_difference '@patient.assessments.count', 0 do
      assert_difference '@patient.histories.count', 1 do
        ConsumeAssessmentsJob.perform_async(@assessment_generator.error_sms_assessment)
        @patient.reload
      end
    end
  end

  test 'consume errored sms assessment retry-eligible error resets last_assessment_reminder_sent' do
    error_code = TwilioSender.retry_eligible_error_codes.first
    @patient.update(preferred_contact_method: 'SMS Texted Weblink', last_assessment_reminder_sent: DateTime.now)
    assert_difference '@patient.assessments.count', 0 do
      assert_difference '@patient.histories.count', 1 do
        assert_changes '@patient.last_assessment_reminder_sent' do
          ConsumeAssessmentsJob.perform_async(@assessment_generator.error_sms_assessment(error_code: error_code))
          @patient.reload
        end
      end
    end
  end

  test 'consume errored voice assessment' do
    @patient.update(preferred_contact_method: 'Telephone Call')
    assert_difference '@patient.assessments.count', 0 do
      assert_difference '@patient.histories.count', 1 do
        ConsumeAssessmentsJob.perform_async(@assessment_generator.error_voice_assessment)
        @patient.reload
      end
    end
  end

  test 'consume errored sms assessment with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))
    @patient.update(preferred_contact_method: 'SMS Texted Weblink')
    assert_difference '@patient.assessments.count', 0 do
      assert_difference 'dependent.assessments.count', 0 do
        assert_difference 'dependent.histories.count', 1 do
          # Assert that patient (HoH) gets a history item for themseleves and their dependent
          assert_difference '@patient.histories.count', 2 do
            ConsumeAssessmentsJob.perform_async(@assessment_generator.error_sms_assessment)
            ConsumeAssessmentsJob.perform_async(@assessment_generator.error_sms_assessment(patient: dependent))
            @patient.reload
            dependent.reload
          end
        end
      end
    end
  end

  test 'consume errored voice assessment with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))
    @patient.update(preferred_contact_method: 'Telephone Call')
    assert_difference '@patient.assessments.count', 0 do
      assert_difference 'dependent.assessments.count', 0 do
        assert_difference 'dependent.histories.count', 1 do
          assert_difference '@patient.histories.count', 1 do
            ConsumeAssessmentsJob.perform_async(@assessment_generator.error_voice_assessment)
            @patient.reload
            dependent.reload
          end
        end
      end
    end
  end
end
