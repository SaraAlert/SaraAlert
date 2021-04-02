# frozen_string_literal: true

require 'application_system_test_case'

SimpleCov.command_name 'SystemTestCaseEnrollerEnrollment'

require_relative 'enroller_test_helper'

class EnrollerEnrollmentTest < ApplicationSystemTestCase
  @@enroller_test_helper = EnrollerTestHelper.new(nil)

  test 'enroll monitoree with all fields as epi' do
    @@enroller_test_helper.enroll_monitoree('state1_epi_enroller', 'monitoree_2', is_epi: true)
  end

  test 'enroll monitoree with last date of exposure' do
    @@enroller_test_helper.enroll_monitoree('locals1c2_enroller', 'monitoree_3')
  end

  test 'enroll monitoree with continuous exposure' do
    @@enroller_test_helper.enroll_monitoree('locals1c2_enroller', 'monitoree_19')
  end

  test 'enroll case with symptom onset' do
    @@enroller_test_helper.enroll_monitoree('locals2c4_enroller', 'monitoree_17')
  end

  test 'enroll case with first positive lab' do
    @@enroller_test_helper.enroll_monitoree('locals1c1_enroller', 'monitoree_18')
  end

  test 'enroll monitoree with jurisdiction within hierarchy' do
    @@enroller_test_helper.enroll_monitoree('state1_enroller', 'monitoree_5')
  end

  test 'enroll case with specific jurisdiction' do
    @@enroller_test_helper.enroll_monitoree('state1_enroller', 'monitoree_1')
  end

  test 'enroll monitoree and add group member' do
    @@enroller_test_helper.enroll_group_member('state2_enroller', 'monitoree_6', 'monitoree_7')
  end

  test 'enroll monitoree and add group member with foreign address and international planned travel' do
    @@enroller_test_helper.enroll_group_member('locals2c3_enroller', 'monitoree_4', 'monitoree_9')
  end
end
