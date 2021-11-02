# frozen_string_literal: true

require 'test_case'
load 'lib/reports_helper.rb'

class ReportsHelperTest < ActiveSupport::TestCase
  include ReportsHelper

  test 'process' do
    class ::Object::Array
      def commit
        true
      end
    end

    queue = [{status: true}.to_json] # "queue"
    @sleep_seconds = 1 # to ensure it gets reset
    # Assert raises because on the second iteration of the loop the queue will pop nil
    assert_raises(TypeError) do
      error_message = 'ConsumeAssessmentsJob: No valid fields found in message. Skipping.'
      expect_any_instance_of(ActiveSupport::Logger).to(receive(:info).with(error_message))
      process(queue, 0)
      assert_equal(0, @sleep_seconds)
      assert_nil(@msg)
    end
  end

  test 'expotential backoff' do
    15.times do |i|
      # Max 30 seconds
      assert_operator(exponential_backoff(i), :<=, 30)
    end
    # base case
    assert_operator(exponential_backoff(0), :<, 2)
    # base +1 case
    assert_operator(exponential_backoff(1), :<, 3)
  end

  test 'handle complete failure without patient submission token' do
    # No token
    @msg = {}.to_json
    error_message = 'reports:queue_reports process 0: JSON parsed correctly but no submission_token was found. Original error: error'
    expect_any_instance_of(ActiveSupport::Logger).to(receive(:error).with(error_message))
    handle_complete_failure('error', 0)
    assert_nil(@msg)
  end

  test 'handle complete failure msg is invalid' do
    @msg = '{true}' # invalid JSON
    error_message = "reports:queue_reports process 0: Unable to process a report because of error. No submission token could be parsed; the report failed parsing. The report has been skipped."
    expect_any_instance_of(ActiveSupport::Logger).to(receive(:error).with(error_message))
    handle_complete_failure('error', 0)
    assert_nil(@msg)
  end

  test 'handle complete failure msg is valid' do
    @msg = {patient_submission_token: 'submission_token'}.to_json
    error_message = 'reports:queue_reports process 0: Unable to process a report for {"patient_submission_token"=>"submission_token"} because of error. The report has been skipped.'
    expect_any_instance_of(ActiveSupport::Logger).to(receive(:error).with(error_message))
    handle_complete_failure('error', 0)
    assert_nil(@msg)
  end
end
