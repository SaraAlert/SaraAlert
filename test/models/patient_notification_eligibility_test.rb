# frozen_string_literal: true

require 'test_case'

class PatientNotificationEligibilityTest < ActiveSupport::TestCase
  def setup
    # Assume that the default patient created here will have a nil preferred_contact_time
    # and if it will be non-nil, then the specific test can change the Timecop time.
    # Default timezone is Eastern Time.
    Timecop.freeze(Time.now.in_time_zone('Eastern Time (US & Canada)').noon.utc)
    @original_reporting_period = ADMIN_OPTIONS['reporting_period_minutes']
  end

  def teardown
    ADMIN_OPTIONS['reporting_period_minutes'] = @original_reporting_period
    Timecop.return
  end

  def default_days_ago(days)
    (Time.now.in_time_zone('Eastern Time (US & Canada)') - days.days)
  end

  def expected_eligibility(patient, exp_eligibility)
    assert_eligible(patient) if exp_eligibility
    assert_ineligible(patient) unless exp_eligibility
  end

  def assert_eligible(patient)
    scope_eligible = !Patient.better_reminder_eligible.find_by(id: patient.id).nil?
    puts patient.report_eligibility unless scope_eligible
    puts "\nFailing scope eligible test with: #{format_patient_str(patient)}" unless scope_eligible
    assert scope_eligible
  end

  def assert_ineligible(patient)
    scope_eligible = !Patient.better_reminder_eligible.find_by(id: patient.id).nil?
    puts patient.report_eligibility if scope_eligible
    puts "\nFailing scope ineligible test with: #{format_patient_str(patient)}" if scope_eligible
    assert_not scope_eligible
  end

  def format_patient_str(patient)
    result = ''
    patient.dependents.each do |p|
      attributes = p.attributes.slice(
        'id', 'responder_id', 'head_of_household', 'preferred_contact_method', 'pause_notifications',
        'isolation', 'continuous_exposure', 'last_date_of_exposure', 'created_at',
        'monitoring', 'closed_at', 'last_assessment_reminder_sent', 'latest_assessment_at', 'purged',
        'time_zone', 'preferred_contact_time'
      )
      result += "\n#{attributes}\n"
    end
    result
  end

  def continuous_exposure_dependent_test(patient, exp_eligibility: true)
    dependent = create(
      :patient,
      responder: patient,
      continuous_exposure: true
    )
    expected_eligibility(patient, exp_eligibility)
    dependent.destroy
  end

  def purged_dependent_test(patient, exp_eligibility: false)
    dependent = create(
      :patient,
      responder: patient,
      continuous_exposure: true
    )
    expected_eligibility(patient, true)
    assert_ineligible(dependent)
    dependent.update(purged: true)
    expected_eligibility(patient, exp_eligibility)
    assert_ineligible(dependent)
    dependent.destroy
  end

  def closed_dependent_test(patient, exp_eligibility: false)
    [
      { isolation: true },
      { continuous_exposure: true },
      { last_date_of_exposure: nil, created_at: default_days_ago(5) },
      { last_date_of_exposure: default_days_ago(5), created_at: default_days_ago(5) },
      { last_date_of_exposure: default_days_ago(11), created_at: default_days_ago(20) }
    ].each do |workflow_params|
      dependent_params = {
        responder: patient,
        monitoring: false,
        closed_at: 1.day.ago
      }.merge(workflow_params)
      dependent = create(:patient, dependent_params)
      expected_eligibility(patient, exp_eligibility)
      assert_ineligible(dependent)
      dependent.destroy
    end
  end

  def monitored_dependent_test(patient, exp_eligibility: true)
    [
      { isolation: true },
      { continuous_exposure: true },
      { last_date_of_exposure: nil, created_at: default_days_ago(5) },
      { last_date_of_exposure: default_days_ago(5), created_at: default_days_ago(5) },
      { last_date_of_exposure: default_days_ago(11), created_at: default_days_ago(20) }
    ].each do |workflow_params|
      dependent = create(
        :patient,
        {
          responder: patient,
          monitoring: true,
          closed_at: nil
        }.merge(workflow_params)
      )
      expected_eligibility(patient, exp_eligibility)
      assert_ineligible(dependent)
      dependent.destroy
    end
  end

  def past_monitoring_period_dependent_test(patient, exp_eligibility: false)
    [
      { last_date_of_exposure: nil, created_at: default_days_ago(16) },
      { last_date_of_exposure: default_days_ago(16), created_at: default_days_ago(16) },
      { last_date_of_exposure: default_days_ago(16), created_at: default_days_ago(30) }
    ].each do |workflow_params|
      dependent = create(
        :patient,
        {
          responder: patient,
          monitoring: true,
          closed_at: nil
        }.merge(workflow_params)
      )
      expected_eligibility(patient, exp_eligibility)
      assert_ineligible(dependent)
      dependent.destroy
    end
  end

  ##
  # Certain dependent fields should not affect notification eligibility of the HoH:
  # - preferred_contact_method
  # - last_assessment_reminder_sent
  # - pause_notifications
  # - latest_assessment_at
  test 'ignored dependent eligibility fields' do
    patient = create(:patient, preferred_contact_method: 'E-mailed Web Link', monitoring: false, closed_at: default_days_ago(1))
    eligible_dependent_params = { continuous_exposure: true }
    ineligible_dependent_params = { monitoring: false, closed_at: default_days_ago(1) }
    # Expect that the ignored params below will not affect the initial eligibilty found here.
    [
      { preferred_contact_method: 'E-mailed Web Link' },
      { preferred_contact_method: 'SMS Texted Weblink' },
      { preferred_contact_method: 'Telephone call' },
      { preferred_contact_method: 'SMS Text-message' },
      { preferred_contact_method: 'Unknown' },
      { preferred_contact_method: 'Opt-out' },
      { preferred_contact_method: '' },
      { preferred_contact_method: nil },
      { pause_notifications: true },
      { last_assessment_reminder_sent: default_days_ago(0) - 1.hour }
    ].each do |ignored_params|
      # Inegligible dependent should not become eligible
      ineligible_dependent = create(
        :patient,
        { responder: patient }.merge(ineligible_dependent_params).merge(ignored_params)
      )
      expected_eligibility(patient, false)
      # Creating an assessment from today SHOULD NOT affect eligibility
      create(
        :assessment,
        patient: ineligible_dependent,
        symptomatic: false,
        created_at: default_days_ago(0).beginning_of_day
      )
      expected_eligibility(patient, false)

      # Egligible dependent should not become ineligible
      eligible_dependent = create(
        :patient,
        { responder: patient }.merge(eligible_dependent_params).merge(ignored_params)
      )
      expected_eligibility(patient, true)
      # Creating an assessment from today SHOULD NOT affect eligibility
      create(
        :assessment,
        patient: eligible_dependent,
        symptomatic: false,
        created_at: default_days_ago(0).beginning_of_day
      )
      expected_eligibility(patient, true)

      ineligible_dependent.destroy
      eligible_dependent.destroy
    end
  end

  ##
  # Use all of the default dependent helper methods to test that the HoH's
  # notification eligibility is properly affected by having specific
  # configurations of dependent patients.
  test 'HoH notification eligibility affected by dependent flows' do
    patient = create(:patient, preferred_contact_method: 'SMS Text-message', monitoring: false, closed_at: default_days_ago(1))
    assert_ineligible(patient)
    continuous_exposure_dependent_test(patient)
    closed_dependent_test(patient)
    monitored_dependent_test(patient)
    past_monitoring_period_dependent_test(patient)
    purged_dependent_test(patient)
  end

  ##
  # A HoH should be unconditionally ineligible when any of the following are true:
  # - HoH record is purged
  # - HoH notifications are paused
  # - HoH preferred contact method is 'Unknown', 'Opt-out', '', or nil
  test 'HoH unconditionally ineligible flows' do
    [
      { purged: true },
      { pause_notifications: true },
      { preferred_contact_method: 'Unknown' },
      { preferred_contact_method: 'Opt-out' },
      { preferred_contact_method: '' },
      { preferred_contact_method: nil }
    ].each do |ineligible_params|
      patient = create(:patient, ineligible_params)
      assert_ineligible(patient)
      continuous_exposure_dependent_test(patient, exp_eligibility: false)
      closed_dependent_test(patient)
      monitored_dependent_test(patient, exp_eligibility: false)
      past_monitoring_period_dependent_test(patient)
    end
  end

  ##
  # A non-HoH in ANY workflow should be eligible for reminders when they meet
  # all of the following criteria:
  # - notifications are not paused
  # - preferred_contact_method is NOT 'Unknown', 'Opt-out', '', or nil
  # - patient is not purged
  # - patient is not closed
  # - patient is in monitoring
  #
  # Eligibility SHOULD NOT be affected by creating a report from yesterday
  # (when the reporting period is 1 day)
  #
  # Eligibility SHOULD be affected by creating a report from today
  test 'non-HoH, eligible flows' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |preferred_contact_method|
      [
        { isolation: true },
        { continuous_exposure: true },
        { last_date_of_exposure: nil, created_at: default_days_ago(5) },
        { last_date_of_exposure: default_days_ago(5), created_at: default_days_ago(5) },
        { last_date_of_exposure: default_days_ago(11), created_at: default_days_ago(20) }
      ].each do |workflow_params|
        patient = create(
          :patient,
          {
            preferred_contact_method: preferred_contact_method,
            pause_notifications: false,
            purged: false,
            monitoring: true,
            closed_at: nil
          }.merge(workflow_params)
        )
        assert_eligible(patient)
        # Creating an assessment from yesterday SHOULD NOT affect eligibility
        create(
          :assessment,
          patient: patient,
          symptomatic: false,
          created_at: default_days_ago(1).end_of_day
        )
        assert_eligible(patient)
        # Creating an assessment from today SHOULD affect eligibility
        create(
          :assessment,
          patient: patient,
          symptomatic: false,
          created_at: default_days_ago(0).beginning_of_day
        )
        assert_ineligible(patient)
      end
    end
  end

  ##
  # A non-HoH patient in ANY workflow should be ineligible for reminders for any
  # of the following reasons:
  # - `pause_notifications` is false
  # - `monitoring` is false and patient is closed
  # - `last_assessment_reminder_sent` was less than 12 hours ago
  # - `preferred_contact_method` is 'Unknown', 'Opt-out', '', or nil
  test 'non-HoH, workflow-shared, non-eligible flows' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |preferred_contact_method|
      [
        { isolation: true },
        { continuous_exposure: true },
        { last_date_of_exposure: nil, created_at: default_days_ago(5) },
        { last_date_of_exposure: default_days_ago(5), created_at: default_days_ago(5) },
        { last_date_of_exposure: default_days_ago(11), created_at: default_days_ago(20) }
      ].each do |workflow_params|
        [
          { pause_notifications: true },
          { monitoring: false, closed_at: default_days_ago(1) },
          { last_assessment_reminder_sent: default_days_ago(0) - 11.hours },
          { preferred_contact_method: 'Unknown' },
          { preferred_contact_method: 'Opt-out' },
          { preferred_contact_method: '' },
          { preferred_contact_method: nil }
        ].each do |ineligible_params|
          patient_args = {
            preferred_contact_method: preferred_contact_method,
            pause_notifications: false,
            purged: false,
            monitoring: true,
            closed_at: nil
          }.merge(workflow_params).merge(ineligible_params)
          patient = create(:patient, patient_args)
          assert_ineligible(patient)
        end
      end
    end
  end

  ##
  # A non-HoH patient in the exposure workflow should be ineligible for reminders when
  # the 'end of monitoring date has passed'.
  #
  # That date can pass if:
  # - `last_date_of_exposure` was more than `monitoring_period_days` ago
  # - `last_date_of_exposure` is nil and `created_at` was more than `monitoring_period_days` ago
  test 'non-HoH, exposure workflow specific, non-eligible flows' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |preferred_contact_method|
      [
        { last_date_of_exposure: default_days_ago(16), created_at: default_days_ago(20) },
        { last_date_of_exposure: nil, created_at: default_days_ago(16) }
      ].each do |ineligible_params|
        patient_args = {
          preferred_contact_method: preferred_contact_method,
          pause_notifications: false,
          purged: false,
          monitoring: true,
          closed_at: nil
        }.merge(ineligible_params)
        patient = create(:patient, patient_args)
        assert_ineligible(patient)
      end
    end
  end

  # Below are original tests pulled from the Patient model test

  test 'isolation non reporting send report when latest assessment was more than 1 day ago' do
    # patient was created more than 24 hours ago
    patient = create(
      :patient,
      preferred_contact_method: 'E-mailed Web Link',
      monitoring: true,
      purged: false,
      isolation: true,
      created_at: default_days_ago(2)
    )
    # patient has asymptomatic assessment more than 24 hours ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    assert_eligible(patient)
  end

  test 'isolation non reporting send report when no assessments and patient was created more than 1 day ago' do
    # patient was created more than 24 hours ago
    patient = create(
      :patient,
      preferred_contact_method: 'E-mailed Web Link',
      monitoring: true,
      purged: false,
      isolation: true, created_at: default_days_ago(2)
    )
    assert_eligible(patient)
  end

  test 'exposure send report when latest assessment was more than 1 day ago' do
    # patient was created more than 24 hours ago
    patient = create(
      :patient,
      preferred_contact_method: 'E-mailed Web Link',
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: default_days_ago(20),
      last_date_of_exposure: default_days_ago(14)
    )
    # patient has asymptomatic assessment more than 1 day ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: default_days_ago(2))
    assert_eligible(patient)
  end

  test 'exposure send report when no assessments and patient was created more than 1 day ago' do
    # patient was created more than 24 hours ago
    patient = create(
      :patient,
      preferred_contact_method: 'E-mailed Web Link',
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: default_days_ago(2),
      last_date_of_exposure: default_days_ago(14)
    )
    assert_eligible(patient)
  end

  test 'exposure send report without continuous exposure' do
    # patient was created more than 24 hours ago
    patient = create(
      :patient,
      preferred_contact_method: 'E-mailed Web Link',
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: default_days_ago(4),
      last_date_of_exposure: default_days_ago(5)
    )
    # patient has asymptomatic assessment more than 1 day ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: default_days_ago(2))
    assert_eligible(patient)
  end

  test 'exposure send report with continuous exposure' do
    # patient was created more than 24 hours ago
    patient = create(
      :patient,
      preferred_contact_method: 'E-mailed Web Link',
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: default_days_ago(2),
      continuous_exposure: true
    )
    # patient has asymptomatic assessment more than 1 day ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: default_days_ago(2))
    assert_eligible(patient)
  end

  test 'Patients in differing timezones are eligible when expected' do
    [
      { monitored_address_state: 'Florida' },
      { monitored_address_state: 'Colorado' },
      { monitored_address_state: nil, address_state: 'California' },
      {}
    ].each do |patient_params|
      patient = create(
        :patient,
        {
          preferred_contact_method: 'E-mailed Web Link',
          continuous_exposure: true
        }.merge(patient_params)
      )
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).noon) do
        assert_eligible(patient)
        # assessment right before the start of the valid reporting period
        create(
          :assessment,
          patient: patient,
          # converting to UTC because these DB times are assumed to be saved in UTC
          created_at: Time.now.getlocal(patient.address_timezone_offset).yesterday.end_of_day.utc
        )
        assert_eligible(patient)
        # assessment right after the start of the valid reporting period
        create(
          :assessment,
          patient: patient,
          created_at: Time.now.getlocal(patient.address_timezone_offset).beginning_of_day.utc
        )
        assert_ineligible(patient)
      end
    end
  end

  test 'configuring reporting period affects eligibility' do
    # patient was created more than 24 hours ago
    patient = create(
      :patient,
      preferred_contact_method: 'E-mailed Web Link',
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: default_days_ago(4),
      continuous_exposure: true
    )
    assert_eligible(patient)
    ADMIN_OPTIONS['reporting_period_minutes'] = 1440 * 7 # 1 week

    create(
      :assessment,
      patient: patient,
      symptomatic: false,
      created_at: (Time.now.getlocal(patient.address_timezone_offset) - 7.days).end_of_day
    )
    assert_eligible(patient)
    create(
      :assessment,
      patient: patient,
      symptomatic: false,
      created_at: (Time.now.getlocal(patient.address_timezone_offset) - 6.days).beginning_of_day
    )
    assert_ineligible(patient)
  end
end
