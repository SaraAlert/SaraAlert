# frozen_string_literal: true

require 'test_helper'
require 'vcr_setup'

class TwilioSenderTest < ActiveSupport::TestCase
  def setup
    ENV['TWILLIO_STUDIO_FLOW'] = 'test'
    ENV['TWILLIO_SENDING_NUMBER'] = '+15555555555'
  end

  def test_get_number_from_single_message_execution
    # SINGLE_SMS execution ie: weblink, enrollment...
    VCR.use_cassette('get_numbers_from_single_message_execution') do
      # This is the ID for a test studio flow execution, if changes are made
      # to the assertions of this test, you'll have to execute a studio flow
      # in the context of this test run and put the id of that execution here
      execution_id = 'FNf9193a1e62d1333a20a84ef183e751df'
      to_from_numbers = TwilioSender.get_phone_numbers_from_flow_execution(execution_id)
      assert_equal to_from_numbers[:monitoree_number], '+16035555555'
      assert_equal to_from_numbers[:sara_number], ENV['TWILLIO_SENDING_NUMBER']
    end
  end

  def test_get_number_from_voice_assessment_execution
    # Voice assessment execution
    VCR.use_cassette('get_numbers_from_voice_assessment_execution') do
      # This is the ID for a test studio flow execution, if changes are made
      # to the assertions of this test, you'll have to execute a studio flow
      # in the context of this test run and put the id of that execution here
      execution_id = 'FNce1d126c3ed0508a15ba965e4f7197dc'
      to_from_numbers = TwilioSender.get_phone_numbers_from_flow_execution(execution_id)
      assert_equal to_from_numbers[:monitoree_number], '+16035555555'
      assert_equal to_from_numbers[:sara_number], ENV['TWILLIO_SENDING_NUMBER']
    end
  end

  def test_get_number_from_sms_assessment_execution
    # SMS assessment execution
    VCR.use_cassette('get_number_from_sms_assessment_execution') do
      # This is the ID for a test studio flow execution, if changes are made
      # to the assertions of this test, you'll have to execute a studio flow
      # in the context of this test run and put the id of that execution here
      execution_id = 'FN304b09128a4f089b8c57a7e3f7cb2221'
      to_from_numbers = TwilioSender.get_phone_numbers_from_flow_execution(execution_id)
      assert_equal to_from_numbers[:monitoree_number], '+16035555555'
      assert_equal to_from_numbers[:sara_number], ENV['TWILLIO_SENDING_NUMBER']
    end
  end

  def test_get_number_from_inbound_sms_trigger_execution
    # Monitoree sends message outside active execution ie: Start/Stop messages
    VCR.use_cassette('get_numbers_from_inbound_sms_trigger_execution') do
      # This is the ID for a test studio flow execution, if changes are made
      # to the assertions of this test, you'll have to execute a studio flow
      # in the context of this test run and put the id of that execution here
      execution_id = 'FNc2b09bcf7ecaca4e33db739422281fcc'
      to_from_numbers = TwilioSender.get_phone_numbers_from_flow_execution(execution_id)
      assert_equal to_from_numbers[:monitoree_number], '+16035555555'
      assert_equal to_from_numbers[:sara_number], ENV['TWILLIO_SENDING_NUMBER']
    end
  end

  def test_get_number_from_inbound_voice_trigger_execution
    # Monitoree calls Sara Alert
    VCR.use_cassette('get_numbers_from_inbound_voice_trigger_execution') do
      # This is the ID for a test studio flow execution, if changes are made
      # to the assertions of this test, you'll have to execute a studio flow
      # in the context of this test run and put the id of that execution here
      execution_id = 'FN24eda0b89122c73e93e3d59431e9a52a'
      to_from_numbers = TwilioSender.get_phone_numbers_from_flow_execution(execution_id)
      assert_equal to_from_numbers[:monitoree_number], '+16035555555'
      assert_equal to_from_numbers[:sara_number], ENV['TWILLIO_SENDING_NUMBER']
    end
  end
end
