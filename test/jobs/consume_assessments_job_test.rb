# frozen_string_literal: true

require 'test_case'
require_relative '../test_helpers/consume_assessments_job_test_helper'

class ConsumeAssessmentsJobTest < ActiveJob::TestCase
  def setup
    Sidekiq::Testing.fake!
    @redis = Rails.application.config.redis
    @redis_queue = Redis::Queue.new('q_bridge', 'bp_q_bridge', redis: @redis)
    @patient = create(:patient, submission_token: SecureRandom.hex(20), primary_telephone: '(555) 555-0111')
    @assessment_generator = ConsumeAssessmentsJobTestHelper::AssessmentGenerator.new(@patient)
  end

  def teardown
    Sidekiq::Testing.inline!
  end

  test 'consume assessment bad json' do
    @redis_queue.push 'not json'
    # The mocking framework will just return when a 'next' is called
    assert_nil ConsumeAssessmentsJob.perform_now
  end

  ConsumeAssessmentsJobTestHelper::AssessmentGenerator.response_statuses.each do |response_status|
    test "response status #{response_status}" do
      @patient.update(last_assessment_reminder_sent: 1.day.ago)
      assert_difference '@patient.histories.count', 1 do
        @redis_queue.push @assessment_generator.no_answer_assessment(response_status)
        ConsumeAssessmentsJob.perform_now
        @patient.reload
        assert_nil @patient.last_assessment_reminder_sent unless response_status == 'no_answer_sms'
        assert_equal 'Contact Attempt', @patient.histories.first.history_type
        assert_includes @patient.histories.first.comment, @patient.primary_telephone
      end
    end

    test "#{response_status} contact attempt history for dependents" do
      dependent = create(:patient)
      dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))
      @redis_queue.push @assessment_generator.no_answer_assessment(response_status)
      assert_difference 'dependent.histories.count', 1 do
        ConsumeAssessmentsJob.perform_now
        dependent.reload
        assert_equal 'Contact Attempt', dependent.histories.first.history_type
        assert_includes dependent.histories.first.comment.gsub(/\s{2,}/, ' '), 'head of household'
      end
    end
  end

  test 'consume assessment for a patient that has submitted recently' do
    # reporting limit defaults to 15 minutes
    @patient.update(assessments: [create(:assessment, patient: @patient)])
    @redis_queue.push @assessment_generator.generic_assessment(symptomatic: false)
    # The mocking framework will just return when a 'next' is called
    assert_nil ConsumeAssessmentsJob.perform_now
  end

  test 'consume assessment no threshold condition' do
    @redis_queue.push @assessment_generator.missing_threshold_condition
    assert_nil ConsumeAssessmentsJob.perform_now
  end

  test 'consume assessment with reported symptoms' do
    assert_difference '@patient.assessments.count', 1 do
      @redis_queue.push @assessment_generator.reported_symptom_assessment
      ConsumeAssessmentsJob.perform_now
    end
  end

  test 'consume assessment with experiencing symptoms' do
    assert_difference '@patient.assessments.count', 1 do
      # Force experiencing_symptoms to true
      @redis_queue.push @assessment_generator.reported_symptom_assessment(symptomatic: true)
      ConsumeAssessmentsJob.perform_now
      @patient.reload
      assert @patient.assessments.first.symptomatic
    end
  end

  test 'consume generic assessment symptomatic' do
    assert_difference '@patient.assessments.count', 1 do
      @redis_queue.push @assessment_generator.generic_assessment(symptomatic: true)
      ConsumeAssessmentsJob.perform_now
      @patient.reload
      assert @patient.assessments.first.symptomatic
      assert_equal 'Monitoree', @patient.assessments.first.who_reported
    end

    # Bypass latest assessment check
    # This test will highlight a known bug in negating a Bool or Int symptom.
    # To be fixed once PO team approves UI changes that are brought along with fixing the issue.
    # @patient.update(assessments: [])

    # assert_difference '@patient.assessments.count', 1 do
    #   @redis.publish('reports', @assessment_generator.generic_assessment(symptomatic: false))
    #   ConsumeAssessmentsJob.perform_now
    #   @patient.reload
    #   assert_not @patient.assessments.first.symptomatic
    #   assert_equal 'Monitoree', @patient.assessments.first.who_reported
    # end
  end

  test 'consume generic assessment with dependents' do
    dependent = create(:patient)
    dependent.update(responder_id: @patient.id, submission_token: SecureRandom.hex(20))
    assert_difference 'dependent.assessments.count', 1 do
      @redis_queue.push @assessment_generator.generic_assessment(symptomatic: true)
      ConsumeAssessmentsJob.perform_now
      dependent.reload
      assert dependent.assessments.first.symptomatic
      assert_equal 'Proxy', dependent.assessments.first.who_reported
    end
  end
end
