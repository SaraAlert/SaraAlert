# frozen_string_literal: true

require 'test_case'


# If HoH preferred contact method is unknown, opt-out, or blank
# are they still eligible for notifications for dependents? How are they notified?
# - no notification

# What is HoH pauses notifications but has a dependent that is eligible for notifications?
# - they do not recieve notifications for dependents when HoH has notifications paused.

# What if notifications are paused for a dependent?
# - doesn't matter because notification is dependending on the HoH

# What if a report for an otherwise eligible dependent has already been submitted in the past day?
# - Right now they will still get a notification
# - Later we may want to change this.


# What if a reminder has already been sent in the past day for an otherwise eligible dependent?
# - Right now they will still get a notification
# - Later we may want to change this.

# Reminder sent < 12 hours ago means system already sent a reminder today?
# - This is intended

# What determines if a patient is in the exposure workflow?
# * seems like (isolation: false, continuous exposure: false,
# * and seems that monitoring date passed is determined by
# * (last_exposure_date: > 14 days ago) OR (last_exposure_date: nil, created_at: > 14 days ago))
# - isolation: true is the ONLY thing that determines if someone is in the exposure workflow

# When do patients get purged?
# - see purge_job.rb and :purge_eligible scope

# Does (continuous_exposure: true) exclusively determine continuous montioring?
# - YES

# How does `isolation` affect notification eligibility? In the flowchart?
# * seems like it is an automatic NO for "is in exposure workflow"?
# - see above

# What if a patient under continuous monitoring has already submitted a report in the past day?
# - continuous monitoring DOES NOT override

# What if a patient under continuous monitoring has already been sent a reminder in the past day?
# - continuous monitoring DOES NOT override

# Can (monitoring: false) exclusively determine if the record is closed?
# - YES

# What is the isolation workflow? (Referenced in Patient model scopes)
# * it seems like it is just if not in exposure workflow on the flowchart.
# - You are EITHER in the exposure workflow or the isolation workflow

# Data dictionary?
# - https://saraalert.org/wp-content/uploads/2020/11/Sara_Alert_Data_Dictionary_1.16.pdf

# rubocop:disable Metrics/ClassLength
class PatientNotificationEligibilityTest < ActiveSupport::TestCase
  def setup
    @default_purgeable_after = ADMIN_OPTIONS['purgeable_after']
    @default_weekly_purge_warning_date = ADMIN_OPTIONS['weekly_purge_warning_date']
    @default_weekly_purge_date = ADMIN_OPTIONS['weekly_purge_date']
  end

  def teardown
    ADMIN_OPTIONS['purgeable_after'] = @default_purgeable_after
    ADMIN_OPTIONS['weekly_purge_warning_date'] = @default_weekly_purge_warning_date
    ADMIN_OPTIONS['weekly_purge_date'] = @default_weekly_purge_date
  end

  def assert_eligibility(patient, exp_eligibility)
    assert_eligible(patient) if exp_eligibility
    assert_ineligible(patient) if !exp_eligibility
  end

  def assert_eligible(patient)
    eligible = !Patient.reminder_eligible.find_by(id: patient.id).nil?
    puts "Failing eligible test with: #{patient.attributes}" unless eligible
    assert eligible
    assert_equal 1, Patient.reminder_eligible.count
  end

  def assert_ineligible(patient)
    eligible = !Patient.reminder_eligible.find_by(id: patient.id).nil?
    puts "Failing ineligible test with: #{patient.attributes}" if eligible
    assert_not eligible
    assert_equal 0, Patient.reminder_eligible.count
  end

  def continuous_exposure_dependent_test(patient, exp_eligibility=true)
    dependent = create(:patient,
      responder: patient,
      continuous_exposure: true
    )
    assert_eligibility(patient, exp_eligibility)
    dependent.destroy
  end

  def closed_dependent_test(patient, exp_eligibility=false)
    dependent = create(:patient,
      responder: patient,
      isolation: true,
      monitoring: false,
      closed_at: 1.day.ago
    )
    assert_eligibility(patient, exp_eligibility)
    dependent.destroy
  end

  def monitored_dependent_test(patient, exp_eligibility=true)
    [
      { isolation: true },
      { continuous_exposure: true },
      { last_date_of_exposure: nil, created_at: 5.days.ago },
      { last_date_of_exposure: 5.days.ago, created_at: 5.days.ago },
      { last_date_of_exposure: 11.days.ago, created_at: 20.days.ago },
    ].each do |workflow_params|
      dependent = create(:patient,
        {
          responder: patient,
          monitoring: true,
          closed_at: nil
        }.merge(workflow_params)
      )
      assert_eligibility(patient, exp_eligibility)
      dependent.destroy
    end
  end

  def past_monitoring_period_dependent_test(patient, exp_eligibility=false)
    [
      { last_date_of_exposure: nil, created_at: 15.days.ago },
      { last_date_of_exposure: 15.days.ago, created_at: 15.days.ago },
      { last_date_of_exposure: 15.days.ago, created_at: 30.days.ago },
    ].each do |workflow_params|
      dependent = create(:patient,
        {
          responder: patient,
          monitoring: true,
          closed_at: nil
        }.merge(workflow_params)
      )
      assert_eligibility(patient, exp_eligibility)
      dependent.destroy
    end
  end

  test 'HoH unconditionally ineligible flows' do
    [
      { pause_notifications: true },
      { preferred_contact_method: 'Unknown' },
      { preferred_contact_method: 'Opt-out' },
      { preferred_contact_method: '' },
      { preferred_contact_method: nil }
    ].each do |ineligible_params|
      Patient.destroy_all
      patient = create(:patient, ineligible_params)
      assert_ineligible(patient)
      continuous_exposure_dependent_test(patient, false)
      closed_dependent_test(patient)
      monitored_dependent_test(patient, false)
      past_monitoring_period_dependent_test(patient)
    end
  end

  test 'non-HoH, eligible flows' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      [
        { isolation: true },
        { continuous_exposure: true },
        { last_date_of_exposure: nil, created_at: 5.days.ago },
        { last_date_of_exposure: 5.days.ago, created_at: 5.days.ago },
        { last_date_of_exposure: 11.days.ago, created_at: 20.days.ago },
      ].each do |workflow_params|
        Patient.destroy_all
        patient = create(:patient,
          {
            preferred_contact_method: report_method,
            pause_notifications: false,
            purged: false,
            monitoring: true,
            closed_at: nil
          }.merge(workflow_params)
        )
        assert_eligible(patient)
        # Creating an assessment from yesterday SHOULD NOT affect eligibility
        create(:assessment,
          patient: patient,
          symptomatic: false,
          created_at: Time.now.getlocal('-04:00').yesterday.end_of_day
        )
        assert_eligible(patient)
        # Creating an assessment from today SHOULD affect eligibility
        create(:assessment,
          patient: patient,
          symptomatic: false,
          created_at: Time.now.getlocal('-04:00').beginning_of_day
        )
        assert_ineligible(patient)
      end
    end
  end

  test 'non-HoH, workflow-shared, non-eligible flows' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      [
        { isolation: true },
        { continuous_exposure: true },
        { last_date_of_exposure: nil, created_at: 5.days.ago },
        { last_date_of_exposure: 5.days.ago, created_at: 5.days.ago },
        { last_date_of_exposure: 11.days.ago, created_at: 20.days.ago }
      ].each do |workflow_params|
        [
          { pause_notifications: true },
          { monitoring: false, closed_at: 1.day.ago },
          { last_assessment_reminder_sent: 11.hours.ago },
          { preferred_contact_method: 'Unknown' },
          { preferred_contact_method: 'Opt-out' },
          { preferred_contact_method: '' },
          { preferred_contact_method: nil }
        ].each do |ineligible_params|
          Patient.destroy_all
          patient_args = {
            preferred_contact_method: report_method,
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

  test 'non-HoH, special exposure workflow, non-eligible flows' do
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |report_method|
      [
        { last_date_of_exposure: 15.days.ago, created_at: 20.days.ago },
        { last_date_of_exposure: nil, created_at: 15.days.ago }
      ].each do |ineligible_params|
        Patient.destroy_all
        patient_args = {
          preferred_contact_method: report_method,
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
end