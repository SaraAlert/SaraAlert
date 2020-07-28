# frozen_string_literal: true

require 'test_case'
require_relative '../test_helpers/consume_assessments_job_test_helper'

class ConsumeAssessmentsJobTest < ActiveJob::TestCase
  def setup
    @redis = $redis
    @patient = create(:patient, submission_token: SecureRandom.hex(20), primary_telephone: '(555) 555-0111')
    @assessment_generator = ConsumeAssessmentsJobTestHelper::AssessmentGenerator.new(@patient)
  end

  ConsumeAssessmentsJobTestHelper::AssessmentGenerator.response_statuses.each do |response_status|
    test "response status #{response_status}" do
      @patient.update(last_assessment_reminder_sent: 1.day.ago)
      @redis.publish('reports', @assessment_generator.no_answer_assessment(response_status))
      assert_difference '@patient.histories.count', 1 do
        ConsumeAssessmentsJob.perform_now
        @patient.reload
        assert_nil @patient.last_assessment_reminder_sent
        assert_equal 'Contact Attempt', @patient.histories.first.history_type
        assert_includes @patient.histories.first.comment, @patient.primary_telephone
      end
    end
  end
end

