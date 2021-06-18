# frozen_string_literal: true

require 'test_case'

# rubocop:disable Metrics/ClassLength
class PatientTest < ActiveSupport::TestCase
  include PatientHelper

  def setup
    @default_purgeable_after = ADMIN_OPTIONS['purgeable_after']
    @default_weekly_purge_warning_date = ADMIN_OPTIONS['weekly_purge_warning_date']
    @default_weekly_purge_date = ADMIN_OPTIONS['weekly_purge_date']
    # Default time zone is Eastern, so 1800 UTC would be 1300 or 1400 Eastern
    Timecop.freeze(Time.now.utc.change(hour: 18))
  end

  def teardown
    ADMIN_OPTIONS['purgeable_after'] = @default_purgeable_after
    ADMIN_OPTIONS['weekly_purge_warning_date'] = @default_weekly_purge_warning_date
    ADMIN_OPTIONS['weekly_purge_date'] = @default_weekly_purge_date
    Timecop.return
  end

  def formatted_tz_offset(offset)
    # Same formatting as PatientHelper
    (offset.negative? ? '' : '+') + format('%<offset>.2d', offset: offset) + ':00'
  end

  def valid_patient
    build(:patient,
          address_state: 'Oregon',
          date_of_birth: 25.years.ago,
          first_name: 'Test',
          last_name: 'Tester',
          last_date_of_exposure: 4.days.ago.to_date,
          symptom_onset: 4.days.ago.to_date)
  end

  test 'date validation must explicitly be in the format YYYY-MM-DD' do
    patient = create(:patient, purged: false, monitoring: true)
    assert patient.valid?(import: true)
    patient.date_of_birth = '2021-01-01'
    assert patient.valid?(:import)
    patient.date_of_birth = ' 2021-01-01 '
    assert_not patient.valid?(:import)
    patient.date_of_birth = '2021-02-02 2021-01-01'
    assert_not patient.valid?(:import)
    patient.date_of_birth = 'typo2021-01-01'
    assert_not patient.valid?(:import)
    patient.date_of_birth = '2021-01-01typo'
    assert_not patient.valid?(:import)
  end

  test 'date validations cannot be numeric' do
    patient = create(:patient, purged: false, monitoring: true)
    assert patient.valid?(import: true)
    patient.date_of_birth = '2021-01-01'
    assert patient.valid?(:import)
    patient.date_of_birth = 20_210_101
    assert_not patient.valid?(:import)
    assert_equal ['is not a valid date, please use the \'YYYY-MM-DD\' format'], patient.errors[:date_of_birth]
    patient.date_of_birth = 20_210_001
    assert_not patient.valid?(:import)
    assert_equal ['is not a valid date, please use the \'YYYY-MM-DD\' format'], patient.errors[:date_of_birth]
    patient.date_of_birth = 20_210_101.001
    assert_not patient.valid?(:import)
    assert_equal ['is not a valid date, please use the \'YYYY-MM-DD\' format'], patient.errors[:date_of_birth]
  end

  test 'active dependents does NOT include dependents that are purged' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: true, monitoring: false, responder_id: responder.id)

    assert_not responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents does NOT include dependents where monitoring is false' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: false)
    dependent.update!(responder_id: responder.id)

    assert_not responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents does NOT include dependents where they are one day past their last day of monitoring based on LDE' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 15.days.ago)
    dependent.update!(responder_id: responder.id)

    assert_not responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents does NOT include dependents where they are one day past their last day of monitoring based on created_at' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: true, last_date_of_exposure: nil, created_at: 15.days.ago)
    dependent.update!(responder_id: responder.id)

    assert_not responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents defaults to using last_date_of_exposure unless it is nil' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 8.days.ago, created_at: 13.days.ago)
    dependent.update!(responder_id: responder.id)

    # Should be included because LDE is within monitoring period
    assert responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents does NOT include dependents where they are way past their last day of monitoring' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 20.days.ago, created_at: 12.days.ago)
    dependent.update!(responder_id: responder.id)

    assert_not responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents DOES include dependents where they are on their last day of monitoring' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 14.days.ago, created_at: 12.days.ago)
    dependent.update!(responder_id: responder.id)

    assert responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents DOES include dependents that are monitored in isolation, regardless of LDE or created_at' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: true, isolation: true, last_date_of_exposure: nil, created_at: 20.days.ago)
    dependent.update!(responder_id: responder.id)

    assert responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents DOES include dependents that are monitored in continuous exposure, regardless of LDE or created_at' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: true, continuous_exposure: true, last_date_of_exposure: nil, created_at: 20.days.ago)
    dependent.update!(responder_id: responder.id)

    assert responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents does NOT include dependents that are NOT monitored in isolation' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: false, isolation: true, last_date_of_exposure: nil, created_at: 20.days.ago)
    dependent.update!(responder_id: responder.id)

    assert_not responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active dependents does NOT include dependents that are NOT monitored in continuous exposure' do
    responder = create(:patient, purged: false, monitoring: true)
    dependent = create(:patient, purged: false, monitoring: false, continuous_exposure: true, last_date_of_exposure: nil, created_at: 20.days.ago)
    dependent.update!(responder_id: responder.id)

    assert_not responder.active_dependents.pluck(:id).include?(dependent.id)
  end

  test 'active_dependents DOES include the responder if the responder meets the criteria' do
    responder = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 10.days.ago, created_at: 12.days.ago)
    dependent = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 10.days.ago, created_at: 12.days.ago)
    dependent.update!(responder_id: responder.id)

    assert responder.active_dependents.pluck(:id).include?(responder.id)
  end

  test 'active_dependents_exclude_self does NOT include the responder no matter what' do
    responder = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 10.days.ago, created_at: 12.days.ago)
    dependent = create(:patient, purged: false, monitoring: true, last_date_of_exposure: 10.days.ago, created_at: 12.days.ago)
    dependent.update!(responder_id: responder.id)

    assert_not responder.active_dependents_exclude_self.pluck(:id).include?(responder.id)
  end

  # test 'validates last date of exposure date constraints' do
  #   patient = build(:patient, last_date_of_exposure: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, last_date_of_exposure: nil)
  #   assert patient.valid?

  #   patient = build(:patient, last_date_of_exposure: Time.now - 1.day)
  #   assert patient.valid?

  #   patient = build(:patient, last_date_of_exposure: Time.now + 30.days)
  #   assert patient.valid?

  #   patient = build(:patient, last_date_of_exposure: Time.now + 31.days)
  #   assert_not patient.valid?

  #   patient = build(:patient, last_date_of_exposure: Date.new(1900, 1, 1))
  #   assert_not patient.valid?
  # end

  # test 'validates symptom onset date constraints' do
  #   patient = build(:patient, symptom_onset: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, symptom_onset: nil)
  #   assert patient.valid?

  #   patient = build(:patient, symptom_onset: Time.now - 1.day)
  #   assert patient.valid?

  #   patient = build(:patient, symptom_onset: Time.now + 30.days)
  #   assert patient.valid?

  #   patient = build(:patient, symptom_onset: Time.now + 31.days)
  #   assert_not patient.valid?

  #   patient = build(:patient, last_date_of_exposure: Date.new(1900, 1, 1))
  #   assert_not patient.valid?
  # end

  # test 'validates extended isolation is not more than 30 days in the past' do
  #   patient = build(:patient, extended_isolation: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, extended_isolation: nil)
  #   assert patient.valid?

  #   patient = build(:patient, extended_isolation: Time.now + 1.day)
  #   assert patient.valid?

  #   patient = build(:patient, extended_isolation: Time.now - 30.days)
  #   assert patient.valid?

  #   patient = build(:patient, extended_isolation: Time.now - 31.days)
  #   assert_not patient.valid?
  # end

  # test 'validates date of birth date constraints' do
  #   patient = build(:patient, date_of_birth: nil)
  #   assert patient.valid?

  #   patient = build(:patient, date_of_birth: 25.years.ago)
  #   assert patient.valid?

  #   patient = build(:patient, date_of_birth: Date.new(1800, 1, 1))
  #   assert_not patient.valid?

  #   patient = build(:patient, date_of_birth: 1.day.from_now)
  #   assert_not patient.valid?
  # end

  # test 'validates date of departure date constraints' do
  #   patient = build(:patient, date_of_departure: Date.new(2020, 1, 1))
  #   assert patient.valid?

  #   patient = build(:patient, date_of_departure: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, date_of_departure: nil)
  #   assert patient.valid?

  #   patient = build(:patient, date_of_departure: Date.new(1900, 1, 1))
  #   assert_not patient.valid?

  #   patient = build(:patient, date_of_departure: 31.days.from_now)
  #   assert_not patient.valid?
  # end

  # test 'validates date of arrival date constraints' do
  #   patient = build(:patient, date_of_arrival: Date.new(2020, 1, 1))
  #   assert patient.valid?

  #   patient = build(:patient, date_of_arrival: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, date_of_arrival: nil)
  #   assert patient.valid?

  #   patient = build(:patient, date_of_arrival: Date.new(1900, 1, 1))
  #   assert_not patient.valid?

  #   patient = build(:patient, date_of_arrival: 31.days.from_now)
  #   assert_not patient.valid?
  # end

  # test 'validates additional planned travel start date constraints' do
  #   patient = build(:patient, additional_planned_travel_start_date: Date.new(2020, 1, 1))
  #   assert patient.valid?

  #   patient = build(:patient, additional_planned_travel_start_date: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, additional_planned_travel_start_date: nil)
  #   assert patient.valid?

  #   patient = build(:patient, additional_planned_travel_start_date: Date.new(1900, 1, 1))
  #   assert_not patient.valid?

  #   patient = build(:patient, additional_planned_travel_start_date: 31.days.from_now)
  #   assert_not patient.valid?
  # end

  # test 'validates additional planned travel end date constraints' do
  #   patient = build(:patient, additional_planned_travel_end_date: Date.new(2020, 1, 1))
  #   assert patient.valid?

  #   patient = build(:patient, additional_planned_travel_end_date: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, additional_planned_travel_end_date: nil)
  #   assert patient.valid?

  #   patient = build(:patient, additional_planned_travel_end_date: Date.new(1900, 1, 1))
  #   assert_not patient.valid?

  #   patient = build(:patient, additional_planned_travel_end_date: 31.days.from_now)
  #   assert_not patient.valid?
  # end

  # test 'validates extended isolation date constraints' do
  #   patient = build(:patient, extended_isolation: nil)
  #   assert patient.valid?

  #   patient = build(:patient, extended_isolation: Time.now)
  #   assert patient.valid?

  #   patient = build(:patient, extended_isolation: 31.days.ago)
  #   assert_not patient.valid?

  #   patient = build(:patient, extended_isolation: 31.days.from_now)
  #   assert_not patient.valid?
  # end

  test 'can update patients with out of range dates' do
    # Create & save a patient with an invalid date field to confirm that updating patients
    # unrelated attributes will not cause an error
    patient = build(:patient, date_of_birth: Date.new(1800, 1, 1))
    patient.save(validate: false)

    assert patient.update(first_name: 'test')
  end

  test 'close eligible does not include purged records' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test with purged set to true
    patient = create(:patient,
                     purged: true,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does not include records in isolation' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test with isolation set to true
    patient = create(:patient,
                     purged: false,
                     isolation: true,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does not include symptomatic records' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test with non-nil symptom onset
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: 1.day.ago,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does not include already closed records' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test with monitoring set to false
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: false,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does not include records in continuous exposure' do
    # Control test
    patient = create(:patient,
                     continuous_exposure: false,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test with continuous exposure set to true
    patient = create(:patient,
                     continuous_exposure: true,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does not include records that have NOT reported in the last 24 hours and were created more than 24 hours ago' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     created_at: 2.days.ago,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test with latest_assessment_at set to two days ago and create_at set to two days ago
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: 2.days.ago,
                     created_at: 2.days.ago,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does NOT include records that have never reported' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now.getlocal('-05:00'),
                     created_at: 2.days.ago,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: nil,
                     created_at: 2.days.ago,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does NOT include records that have NOT reported today (based on their timezone)' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now.getlocal('-05:00'),
                     created_at: 2.days.ago,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: 1.day.ago.getlocal('-05:00'),
                     created_at: 2.days.ago,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible does not include records still within their monitoring period' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test where patient is still within their monitoring period
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 2.days.ago)

    assert_equal(0, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible includes records on their last day of monitoring' do
    # Control test
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)

    # Test where patient is on the last day of their monitoring period
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 14.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible includes records past their last day of monitoring' do
    # This was tested in most control tests, but testing when last date of exposure is 15 days ago and the record was created only 5 days ago
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 15.days.ago,
                     created_at: 5.days.ago)

    assert_equal(1, Patient.close_eligible.select { |p| p.id == patient.id }.count)
  end

  test 'close eligible includes records that have been inactive for 30+ days' do
    # 30 day border is sensitive to DST changes
    patient = create(
      :patient,
      isolation: false,
      monitoring: true,
      purged: false,
      public_health_action: 'None',
      symptom_onset: nil
    )
    patient.update(created_at: 50.days.ago)
    patient.update(updated_at: 31.days.ago)
    assert_not_nil Patient.close_eligible.find_by(id: patient.id)
    patient.update(updated_at: 50.days.ago)
    assert_not_nil Patient.close_eligible.find_by(id: patient.id)
  end

  # Patients who are eligible for reminders:
  #   - not purged AND
  #   - notifications not paused AND
  #   - valid preferred contact method AND
  #   - HoH or not in a household AND
  #   - we haven't sent them an assessment within the past 12 hours AND
  #   - they haven't completed an assessment today OR they haven't completed an assessment at all
  #
  test 'reminder eligible does not include purged records' do
    patient = create(:patient,
                     purged: true,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records with paused notifications' do
    patient = create(:patient,
                     purged: false,
                     pause_notifications: true,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records with invalid, unknown, or opt-out contact methods' do
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: '')

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: nil)

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Unknown')

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Opt-out')

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records that report through a HoH' do
    responder = create(:patient,
                       purged: false,
                       pause_notifications: false,
                       monitoring: true,
                       preferred_contact_method: 'Telephone call',
                       primary_telephone: '+13333333333')

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')

    patient.update!(responder_id: responder.id)
    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records have received an assessment reminder in the last 12 hours' do
    # Assessment was sent yesterday in patient local time - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')
    patient_local_time = Time.now.getlocal(patient.address_timezone_offset)
    patient.update(last_assessment_reminder_sent: correct_dst_edge(patient, patient_local_time.yesterday.end_of_day))

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was not sent (nil) - should be eligible
    patient.update(last_assessment_reminder_sent: nil)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was sent at the beginning of the day in patient local time - should not be eligible
    patient.update(last_assessment_reminder_sent: correct_dst_edge(patient, patient_local_time.beginning_of_day))

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was sent noon today in patient local time - should NOT be eligible
    patient.update(last_assessment_reminder_sent: patient_local_time.change(hour: 12))

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records that have completed an assessment today' do
    # Assessment was completed more than a day ago - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333',
                     latest_assessment_at: 25.hours.ago)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was not completed (nil) - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333',
                     latest_assessment_at: nil)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was completed at the very beginning of the day - should NOT be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333',
                     latest_assessment_at: Time.now.in_time_zone('Eastern Time (US & Canada)').beginning_of_day)

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was completed now - should NOT be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333',
                     latest_assessment_at: Time.now)

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'create patient' do
    assert patient = create(:patient)
    assert_nil patient.symptom_onset
    assert_nil patient.latest_assessment_at
    assert_equal false, patient.latest_assessment_symptomatic
    assert_nil patient.latest_fever_or_fever_reducer_at
    assert_empty patient.assessments
    assert_nil patient.first_positive_lab_at
    assert patient.negative_lab_count.zero?
    assert_empty patient.laboratories
    assert_nil patient.latest_transfer_at
    assert_nil patient.latest_transfer_from
    assert_empty patient.transfers
  end

  test 'report eligibility' do
    patient = create(:patient, purged: true)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'purged'

    patient = create(:patient, pause_notifications: true)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'paused'

    patient = create(:patient, monitoring: false)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'Monitoree is not currently being monitored'

    patient = create(:patient)
    patient.update(responder: create(:patient))
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'household'

    patient = create(:patient, preferred_contact_method: 'Unknown')
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'ineligible preferred contact method'

    patient = create(:patient,
                     isolation: false,
                     last_date_of_exposure: 30.days.ago,
                     continuous_exposure: false,
                     preferred_contact_method: 'Telephone call',
                     primary_telephone: '+13333333333')
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'monitoring period has elapsed'

    patient = create(:patient, preferred_contact_method: 'Telephone call', primary_telephone: '+13333333333', last_assessment_reminder_sent: 1.hour.ago)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'contacted recently'

    patient = create(:patient, preferred_contact_method: 'Telephone call', primary_telephone: '+13333333333', latest_assessment_at: 1.hour.ago)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'already reported'

    patient = create(:patient, preferred_contact_method: 'Telephone call', primary_telephone: '+13333333333', preferred_contact_time: 'Morning')
    assert patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? '8:00 AM local time (Morning)'

    patient = create(:patient, preferred_contact_method: 'Telephone call', primary_telephone: '+13333333333', preferred_contact_time: 'Afternoon')
    assert patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? '12:00 PM local time (Afternoon)'

    patient = create(:patient, preferred_contact_method: 'Telephone call', primary_telephone: '+13333333333', preferred_contact_time: 'Evening')
    assert patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? '4:00 PM local time (Evening)'

    patient = create(:patient, preferred_contact_method: 'Telephone call', primary_telephone: '+13333333333')
    assert patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'Today'
  end

  test 'monitoring open' do
    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 1, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 0, Patient.monitoring_open.where(id: patient.id).count
  end

  test 'monitoring closed' do
    patient = create(:patient, monitoring: false)
    assert_equal 1, Patient.monitoring_closed.where(id: patient.id).count

    patient = create(:patient, monitoring: true)
    assert_equal 0, Patient.monitoring_closed.where(id: patient.id).count
  end

  test 'monitoring closed without purged' do
    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 1, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 0, Patient.monitoring_closed_without_purged.where(id: patient.id).count
  end

  test 'monitoring closed with purged' do
    patient = create(:patient, monitoring: false, purged: true)
    assert_equal 1, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: false)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: true, purged: true)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count

    patient = create(:patient, monitoring: false, purged: false)
    assert_equal 0, Patient.monitoring_closed_with_purged.where(id: patient.id).count
  end

  test 'purge eligible' do
    Patient.destroy_all
    patient = create(:patient)

    # Updated at of today, still monitoring, should not be purgeable
    assert_equal 0, Patient.purge_eligible.count
    patient.update!(monitoring: false)

    # Updated as of today, not monitoring, should not be purgeable
    assert_equal 0, Patient.purge_eligible.count

    # Updated 2x before purgeable_after, not monitoring, should obviously be purgeable regardless of weekly_purge_date and weekly_purge_warning_date
    patient.update!(updated_at: (2 * ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert_equal 1, Patient.purge_eligible.count

    # If the patient was last updated within the purgeable_after timeframe, do not purge
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 2.5.days + 1.minute).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'].minutes - 900.minutes).ago)
    assert_equal 0, Patient.purge_eligible.count

    # If the patient was last updated exactly at the purgeable_after timeframe, they should not be purgeable
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert_equal 0, Patient.purge_eligible.count
  end

  test 'continuous_exposure never purge eligible' do
    patient = create(:patient, purged: false, monitoring: false, continuous_exposure: true)
    patient.update!(updated_at: (2 * ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert_nil Patient.purge_eligible.find_by_id(patient.id)
  end

  test 'purged' do
    patient = create(:patient, purged: false)
    assert_equal 0, Patient.purged.where(id: patient.id).count

    patient = create(:patient, purged: true)
    assert_equal 1, Patient.purged.where(id: patient.id).count
  end

  test 'confirmed case' do
    patient = create(:patient, monitoring_reason: 'Case confirmed')
    assert_equal 1, Patient.confirmed_case.where(id: patient.id).count

    patient = create(:patient, monitoring_reason: 'Completed Monitoring')
    assert_equal 0, Patient.confirmed_case.where(id: patient.id).count

    patient = create(:patient)
    assert_equal 0, Patient.confirmed_case.where(id: patient.id).count
  end

  test 'exposure symptomatic' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    create(:assessment, patient: patient, symptomatic: true)
    verify_patient_status(patient, :exposure_symptomatic)

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: true, created_at: 25.hours.ago)
    verify_patient_status(patient, :exposure_symptomatic)
  end

  test 'exposure non reporting' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    verify_patient_status(patient, :exposure_non_reporting)

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    verify_patient_status(patient, :exposure_non_reporting)
  end

  test 'exposure asymptomatic' do
    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None')
    verify_patient_status(patient, :exposure_asymptomatic)

    patient = create(:patient, monitoring: true, purged: false, public_health_action: 'None', created_at: 25.hours.ago)
    create(:assessment, patient: patient, symptomatic: false)
    verify_patient_status(patient, :exposure_asymptomatic)
  end

  test 'exposure under investigation' do
    patient = create(:patient, monitoring: true, purged: false, isolation: false, public_health_action: 'Recommended laboratory testing')
    verify_patient_status(patient, :exposure_under_investigation)
  end

  test 'isolation asymp non test based' do
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 14.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)

    # meets definition: asymptomatic after positive test result
    laboratory = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 15.days.ago)
    assessment = create(:assessment, patient: patient, symptomatic: false, created_at: 8.days.ago)
    verify_patient_status(patient, :isolation_asymp_non_test_based)
    laboratory.destroy
    assessment.destroy

    # meets defiition: has positive test result more than 10 days ago and another positive test result less than 10 days ago
    laboratory_1 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 11.days.ago)
    laboratory_2 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 9.days.ago)
    assessment = create(:assessment, patient: patient, symptomatic: false, created_at: 8.days.ago)
    verify_patient_status(patient, :isolation_asymp_non_test_based)
    assessment.destroy
    laboratory_1.destroy
    laboratory_2.destroy

    # does not meet definition: symptomatic before positive test result but not afterwards
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    laboratory = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 11.days.ago)
    verify_patient_status(patient, :isolation_symp_non_test_based)
    assessment.destroy
    laboratory.destroy

    # does not meet defiition: has positive test result less than 10 days ago
    laboratory = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 8.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    laboratory.destroy

    # does not meet defiition: has negative test result more than 10 days ago, but also has positive test result less than 10 days ago
    laboratory_1 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: 11.days.ago)
    laboratory_2 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 9.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    laboratory_1.destroy
    laboratory_2.destroy

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    laboratory_1 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 11.days.ago)
    laboratory_2 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: 9.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    laboratory_1.destroy
    laboratory_2.destroy

    # does not meet definition: symptomatic after positive test result
    laboratory = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 15.days.ago)
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 8.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    assessment.destroy
    laboratory.destroy

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    laboratory = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 13.days.ago)
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    verify_patient_status(patient, :isolation_symp_non_test_based)
    assessment.destroy
    laboratory.destroy

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    laboratory_1 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 12.days.ago)
    assessment_1 = create(:assessment, patient: patient, symptomatic: true, created_at: 6.days.ago)
    assessment_2 = create(:assessment, patient: patient, symptomatic: false, created_at: 5.days.ago)
    laboratory_2 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: 3.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    assessment_1.destroy
    assessment_2.destroy
    laboratory_1.destroy
    laboratory_2.destroy

    # does not meet definition: symptomatic after positive test result even though symptomatic more than 10 days ago
    laboratory_1 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 15.days.ago)
    assessment_1 = create(:assessment, patient: patient, symptomatic: true, created_at: 14.days.ago)
    assessment_2 = create(:assessment, patient: patient, symptomatic: false, created_at: 13.days.ago)
    laboratory_2 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: 12.days.ago)
    verify_patient_status(patient, :isolation_symp_non_test_based)
    assessment_1.destroy
    assessment_2.destroy
    laboratory_1.destroy
    laboratory_2.destroy
  end

  test 'isolation symp non test based' do
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 14.days.ago, symptom_onset: 12.days.ago)

    # meets definition: symptomatic assessment older than 24 hours
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 11.days.ago)
    verify_patient_status(patient, :isolation_symp_non_test_based)
    assessment.destroy

    # meets definition: had an assessment with no fever
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 12.days.ago)
    reported_condition = create(:reported_condition, assessment: assessment)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: false)
    verify_patient_status(patient, :isolation_symp_non_test_based)
    assessment.destroy

    # meets definition: had a fever but more than 24 hours ago
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 13.days.ago)
    reported_condition = create(:reported_condition, assessment: assessment)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true)
    verify_patient_status(patient, :isolation_symp_non_test_based)
    assessment.destroy

    # does not meet definition: symptom onset not more than 10 days ago
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 9.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    assessment.destroy

    # does not meet definition: had a fever within the past 24 hours
    assessment_1 = create(:assessment, patient: patient, symptomatic: true, created_at: 11.days.ago)
    assessment_2 = create(:assessment, patient: patient, symptomatic: true, created_at: 22.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2, created_at: 22.hours.ago)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'fever', bool_value: true, created_at: 22.hours.ago)
    patient.reload.latest_fever_or_fever_reducer_at
    verify_patient_status(patient, :isolation_reporting)
    assessment_1.destroy
    assessment_2.destroy

    # does not meet definition: used a fever reducer within the past 24 hours
    assessment_1 = create(:assessment, patient: patient, symptomatic: true, created_at: 80.hours.ago)
    assessment_2 = create(:assessment, patient: patient, symptomatic: true, created_at: 21.hours.ago)
    reported_condition = create(:reported_condition, assessment: assessment_2)
    create(:symptom, condition_id: reported_condition.id, type: 'BoolSymptom', name: 'used-a-fever-reducer', bool_value: true)
    patient.reload.latest_fever_or_fever_reducer_at
    verify_patient_status(patient, :isolation_reporting)
    assessment_1.destroy
    assessment_2.destroy
  end

  test 'isolation test based' do
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true)

    # meets definition: has at least 1 assessment and 2 negative test results
    assessment = create(:assessment, patient: patient, created_at: 50.days.ago)
    laboratory_1 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: 50.days.ago)
    laboratory_2 = create(:laboratory, patient: patient, result: 'negative', specimen_collection: 50.days.ago)
    verify_patient_status(patient, :isolation_test_based)
    assessment.destroy
    laboratory_1.destroy
    laboratory_2.destroy

    # does not meet definition: no assessments
    laboratory_1 = create(:laboratory, patient: patient, result: 'negative')
    laboratory_2 = create(:laboratory, patient: patient, result: 'negative')
    verify_patient_status(patient, :isolation_reporting)
    laboratory_1.destroy
    laboratory_2.destroy

    # does not meet definition: only 1 negative test result
    assessment = create(:assessment, patient: patient)
    laboratory = create(:laboratory, patient: patient, result: 'negative')
    verify_patient_status(patient, :isolation_reporting)
    assessment.destroy
    laboratory.destroy
  end

  test 'isolation reporting' do
    # patient was created less than 24 hours ago
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 16.hours.ago)
    verify_patient_status(patient, :isolation_reporting)

    # patient has asymptomatic assessment less than 24 hours ago
    assessment = create(:assessment, patient: patient, symptomatic: false, created_at: 10.hours.ago)
    verify_patient_status(patient, :isolation_reporting)
    assessment.destroy

    # patient has symptomatic assessment less than 24 hours ago
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 18.hours.ago)
    verify_patient_status(patient, :isolation_reporting)
    assessment.destroy
  end

  test 'isolation non reporting' do
    # patient was created more than 24 hours ago with no assessments
    Patient.destroy_all
    patient = create(:patient, monitoring: true, purged: false, isolation: true, created_at: 2.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)

    # patient has asymptomatic assessment more than 24 hours ago
    assessment = create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    assessment.destroy

    # patient has symptomatic assessment more than 24 hours ago
    assessment = create(:assessment, patient: patient, symptomatic: true, created_at: 28.hours.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    assessment.destroy
  end

  test 'isolation non reporting send report when latest assessment was more than 1 day ago' do
    # patient was created more than 24 hours ago
    Patient.destroy_all
    patient = create(
      :patient,
      monitoring: true,
      purged: false,
      isolation: true,
      created_at: 2.days.ago,
      preferred_contact_method: 'SMS Texted Weblink',
      primary_telephone: '+13333333333'
    )

    # patient has asymptomatic assessment more than 24 hours ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 25.hours.ago)

    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
  end

  test 'isolation non reporting send report when no assessments and patient was created more than 1 day ago' do
    # patient was created more than 24 hours ago
    Patient.destroy_all
    patient = create(
      :patient,
      monitoring: true,
      purged: false,
      isolation: true,
      created_at: 2.days.ago,
      preferred_contact_method: 'SMS Texted Weblink',
      primary_telephone: '+13333333333'
    )

    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
  end

  test 'exposure send report when latest assessment was more than 1 day ago' do
    # patient was created more than 24 hours ago
    Patient.destroy_all
    patient = create(
      :patient,
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: 20.days.ago,
      last_date_of_exposure: 14.days.ago,
      preferred_contact_method: 'SMS Texted Weblink',
      primary_telephone: '+13333333333'
    )

    # patient has asymptomatic assessment more than 1 day ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 2.days.ago)

    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
  end

  test 'exposure send report when no assessments and patient was created more than 1 day ago' do
    # patient was created more than 24 hours ago
    Patient.destroy_all
    patient = create(
      :patient,
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: 2.days.ago,
      last_date_of_exposure: 14.days.ago,
      preferred_contact_method: 'SMS Texted Weblink',
      primary_telephone: '+13333333333'
    )

    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
  end

  test 'exposure send report without continuous exposure' do
    # patient was created more than 24 hours ago
    Patient.destroy_all
    patient = create(
      :patient,
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: 4.days.ago,
      last_date_of_exposure: 5.days.ago,
      preferred_contact_method: 'SMS Texted Weblink',
      primary_telephone: '+13333333333'
    )

    # patient has asymptomatic assessment more than 1 day ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 2.days.ago)

    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
  end

  test 'exposure send report with continuous exposure' do
    # patient was created more than 24 hours ago
    Patient.destroy_all
    patient = create(
      :patient,
      monitoring: true,
      purged: false,
      isolation: false,
      created_at: 4.days.ago,
      continuous_exposure: true,
      preferred_contact_method: 'SMS Texted Weblink',
      primary_telephone: '+13333333333'
    )

    # patient has asymptomatic assessment more than 1 day ago but less than 7 days ago
    create(:assessment, patient: patient, symptomatic: false, created_at: 2.days.ago)

    assert_not Patient.reminder_eligible.find_by(id: patient.id).nil?
  end

  test 'address timezone offset' do
    jur = Jurisdiction.create
    user = User.create!(
      email: 'foobar@example.com',
      password: '1234567ab!',
      jurisdiction: jur,
      force_password_change: true # Require user to change password on first login
    )
    Patient.destroy_all
    patient = Patient.new(creator: user, jurisdiction: jur)
    assert patient.address_timezone_offset == formatted_tz_offset(Time.now.in_time_zone('US/Eastern').utc_offset / 60 / 60)
    patient.update(address_state: 'California')
    assert patient.address_timezone_offset == formatted_tz_offset(Time.now.in_time_zone('US/Pacific').utc_offset / 60 / 60)
    patient.update(monitored_address_state: 'Northern Mariana Islands')
    assert patient.address_timezone_offset == formatted_tz_offset(Time.now.in_time_zone('Guam').utc_offset / 60 / 60)
  end

  def verify_patient_status(patient, status)
    patients = Patient.where(id: patient.id)

    assert patients.symptomatic.exists? if status == :exposure_symptomatic
    assert patients.non_reporting.exists? if status == :exposure_non_reporting
    assert patients.asymptomatic.exists? if status == :exposure_asymptomatic

    assert_equal status == :purged, patients.purged.exists?
    assert_equal status == :closed, patients.monitoring_closed_without_purged.exists?

    assert_equal status == :exposure_symptomatic, patients.exposure_symptomatic.exists?
    assert_equal status == :exposure_non_reporting, patients.exposure_non_reporting.exists?
    assert_equal status == :exposure_asymptomatic, patients.exposure_asymptomatic.exists?
    assert_equal status == :exposure_under_investigation, patients.exposure_under_investigation.exists?

    assert_equal status == :isolation_asymp_non_test_based, patients.isolation_asymp_non_test_based.exists?
    assert_equal status == :isolation_symp_non_test_based, patients.isolation_symp_non_test_based.exists?
    assert_equal status == :isolation_test_based, patients.isolation_test_based.exists?

    isolation_requiring_review = %i[isolation_asymp_non_test_based isolation_symp_non_test_based isolation_test_based].include?(status)
    assert_equal isolation_requiring_review, patients.isolation_requiring_review.exists?

    assert_equal status == :isolation_reporting, patients.isolation_reporting.exists?
    assert_equal status == :isolation_non_reporting, patients.isolation_non_reporting.exists?

    assert_equal status, patient.status
  end

  test 'calc current age (instance)' do
    number = rand(100)
    patient = create(:patient, date_of_birth: number.years.ago)
    assert_equal number, patient.calc_current_age
  end

  test 'calc current age fhir' do
    number = rand(100)
    patient = create(:patient, date_of_birth: number.years.ago)
    age = patient.calc_current_age

    birth_year = Date.today.year - age

    assert_equal age, Patient.calc_current_age_fhir("#{birth_year}-01-01")
    assert_equal age, Patient.calc_current_age_fhir("#{birth_year}-01")
    assert_equal age, Patient.calc_current_age_fhir(birth_year.to_s)

    assert_nil Patient.calc_current_age_fhir(nil)
  end

  test 'refresh head of household' do
    patient = create(:patient)
    dependent = create(:patient, responder: patient)
    assert patient.reload.head_of_household
    assert_not dependent.reload.head_of_household

    new_head = create(:patient)
    dependent.update(responder: new_head)
    assert_not patient.reload.head_of_household
    assert new_head.reload.head_of_household
    assert_not dependent.reload.head_of_household

    dependent.destroy
    assert_not patient.reload.head_of_household
    assert_not new_head.reload.head_of_household
  end

  test 'validates address_state inclusion in api and import context' do
    patient = valid_patient

    patient.address_state = 'Georgia'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.address_state = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates primary_language inclusion in api and import context' do
    patient = valid_patient

    patient.primary_language = 'eng'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_language = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_language = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_language = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates secondary_language inclusion in api and import context' do
    patient = valid_patient

    patient.secondary_language = 'spa'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_language = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_language = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_language = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates monitored_address_state inclusion in api and import context' do
    patient = valid_patient

    patient.monitored_address_state = 'Oregon'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.monitored_address_state = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.monitored_address_state = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.monitored_address_state = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates foreign_monitored_address_state inclusion in api and import context' do
    patient = valid_patient

    patient.foreign_monitored_address_state = 'Oregon'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.foreign_monitored_address_state = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.foreign_monitored_address_state = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.foreign_monitored_address_state = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates additional_planned_travel_destination_state inclusion in api and import context' do
    patient = valid_patient

    patient.additional_planned_travel_destination_state = 'Oregon'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_destination_state = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_destination_state = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_destination_state = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates ethnicity inclusion in api and import context' do
    patient = valid_patient

    patient.ethnicity = 'Hispanic or Latino'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.ethnicity = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.ethnicity = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.ethnicity = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates preferred contact method inclusion in api and import context' do
    patient = valid_patient

    patient.preferred_contact_method = 'Unknown'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.preferred_contact_method = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.preferred_contact_method = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.preferred_contact_method = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates preferred contact time inclusion in api and import context' do
    patient = valid_patient

    patient.preferred_contact_time = 'Morning'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.preferred_contact_time = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.preferred_contact_time = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.preferred_contact_time = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates sex inclusion in api and import context' do
    patient = valid_patient

    patient.sex = 'Female'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.sex = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.sex = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.sex = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates primary_telephone_type inclusion in api and import context' do
    patient = valid_patient

    patient.primary_telephone_type = 'Smartphone'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone_type = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone_type = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone_type = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates secondary_telephone_type inclusion in api and import context' do
    patient = valid_patient

    patient.secondary_telephone_type = 'Smartphone'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_telephone_type = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_telephone_type = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_telephone_type = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates additional_planned_travel_type inclusion in api and import context' do
    patient = valid_patient

    patient.additional_planned_travel_type = 'Domestic'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_type = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_type = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_type = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates monitoring_plan inclusion' do
    patient = valid_patient

    patient.monitoring_plan = 'None'
    assert patient.valid?

    patient.monitoring_plan = ''
    assert patient.valid?

    patient.monitoring_plan = nil
    assert patient.valid?

    patient.monitoring_plan = 'foo'
    assert_not patient.valid?
  end

  test 'validates monitoring_reason inclusion' do
    patient = valid_patient

    patient.monitoring_reason = 'Other'
    assert patient.valid?

    patient.monitoring_reason = ''
    assert patient.valid?

    patient.monitoring_reason = nil
    assert patient.valid?

    patient.monitoring_reason = 'foo'
    assert_not patient.valid?
  end

  test 'validates exposure_risk_assessment inclusion' do
    patient = valid_patient

    patient.exposure_risk_assessment = 'Medium'
    assert patient.valid?

    patient.exposure_risk_assessment = ''
    assert patient.valid?

    patient.exposure_risk_assessment = nil
    assert patient.valid?

    patient.exposure_risk_assessment = 'foo'
    assert_not patient.valid?
  end

  test 'validates case_status inclusion in api and import context' do
    patient = valid_patient

    patient.case_status = 'Confirmed'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.case_status = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.case_status = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.case_status = 'foo'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates primary phone is a possible phone number in api and import context' do
    patient = valid_patient

    patient.primary_telephone = '+15555555555'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone = '+1 555 555 5555'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone = '+1 123 456 7890'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.primary_telephone = '123'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates secondary phone is a possible phone number in api and import context' do
    patient = valid_patient

    patient.secondary_telephone = '+15555555555'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_telephone = '+1 555 555 5555'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_telephone = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.secondary_telephone = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone = '+1 123 456 7890'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.secondary_telephone = '123'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates date_of_birth is a valid date in api and import context' do
    patient = valid_patient

    patient.date_of_birth = 25.years.ago
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.date_of_birth = '01-15-2000'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.date_of_birth = '2000-13-13'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates last_date_of_exposure is a valid date in api and import context' do
    patient = valid_patient

    patient.last_date_of_exposure = 25.years.ago
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.last_date_of_exposure = '01-15-2000'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.last_date_of_exposure = '2000-13-13'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates symptom_onset is a valid date in api and import context' do
    patient = valid_patient

    patient.symptom_onset = 25.years.ago
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.symptom_onset = '01-15-2000'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.symptom_onset = '2000-13-13'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates additional_planned_travel_start_date is a valid date in api and import context' do
    patient = valid_patient

    patient.additional_planned_travel_start_date = 25.years.ago
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_start_date = '01-15-2000'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.additional_planned_travel_start_date = '2000-13-13'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates additional_planned_travel_end_date is a valid date in api and import context' do
    patient = valid_patient

    patient.additional_planned_travel_end_date = 25.years.ago
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.additional_planned_travel_end_date = '01-15-2000'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.additional_planned_travel_end_date = '2000-13-13'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates date_of_departure is a valid date in api and import context' do
    patient = valid_patient

    patient.date_of_departure = 25.years.ago
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.date_of_departure = '01-15-2000'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.date_of_departure = '2000-13-13'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates date_of_arrival is a valid date in api and import context' do
    patient = valid_patient

    patient.date_of_arrival = 25.years.ago
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.date_of_arrival = '01-15-2000'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)

    patient.date_of_arrival = '2000-13-13'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates email is a valid email address in api and import context' do
    patient = valid_patient

    patient.email = 'foo@bar.com'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.email = ''
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.email = nil
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.email = 'not@an@email.com'
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates one of address_state or foreign_address_country is required in api context' do
    patient = valid_patient

    patient.address_state = 'Ohio'
    patient.foreign_address_country = nil
    assert patient.valid?(:api)

    patient.foreign_address_country = 'UK'
    patient.address_state = nil
    assert patient.valid?(:api)

    patient.foreign_address_country = 'UK'
    patient.address_state = 'Ohio'
    assert patient.valid?(:api)

    patient.address_state = nil
    patient.foreign_address_country = nil
    assert_not patient.valid?(:api)
    assert patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates date_of_birth is required in api context' do
    patient = valid_patient

    assert patient.valid?(:api)

    patient.date_of_birth = nil
    assert_not patient.valid?(:api)
    assert patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates first_name is required in api context' do
    patient = valid_patient

    assert patient.valid?(:api)

    patient.first_name = nil
    assert_not patient.valid?(:api)
    assert patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates last_name is required in api context' do
    patient = valid_patient

    assert patient.valid?(:api)

    patient.last_name = nil
    assert_not patient.valid?(:api)
    assert patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates email is not blank when preferred_contact_method is "E-mailed Web Link" in api and import context' do
    patient = valid_patient

    patient.email = 'foo@bar.com'
    patient.preferred_contact_method = 'E-mailed Web Link'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.email = ''
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates primary_telephone is not blank when preferred_contact_method requires a phone in api and import context' do
    patient = valid_patient

    patient.primary_telephone = '+15555555555'
    patient.preferred_contact_method = 'SMS Text-message'
    assert patient.valid?(:api)
    assert patient.valid?(:import)

    patient.primary_telephone = ''
    assert_not patient.valid?(:api)
    assert_not patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates last_date_of_exposure is present when isolation and continuous_exposure are false in api context' do
    patient = valid_patient

    patient.isolation = true
    patient.continuous_exposure = false
    patient.last_date_of_exposure = nil
    assert patient.valid?(:api)

    patient.isolation = false
    patient.continuous_exposure = true
    patient.last_date_of_exposure = nil
    assert patient.valid?(:api)

    patient.isolation = false
    patient.continuous_exposure = false
    patient.last_date_of_exposure = Time.now - 1.day
    assert patient.valid?(:api)

    patient.isolation = false
    patient.continuous_exposure = false
    patient.last_date_of_exposure = nil
    assert_not patient.valid?(:api)
    assert patient.valid?(:import)
    assert patient.valid?
  end

  test 'validates continuous_exposure is false when last_date_of_exposure is present' do
    patient = valid_patient

    patient.continuous_exposure = true
    patient.last_date_of_exposure = nil
    assert patient.valid?(:api)

    patient.continuous_exposure = true
    patient.last_date_of_exposure = ''
    assert patient.valid?(:api)

    patient.continuous_exposure = true
    patient.last_date_of_exposure = Time.now - 1.day
    assert_not patient.valid?(:api)
  end

  test 'validates symptom_onset or asymptomatic postive lab when in isolation' do
    patient = valid_patient

    patient.isolation = true
    patient.symptom_onset = nil
    assert_not patient.valid?(:api_create)

    patient.symptom_onset = 1.day.ago
    assert patient.valid?(:api_create)

    patient.symptom_onset = nil
    patient.laboratories << create(:laboratory, result: 'negative')
    assert_not patient.valid?(:api_create)

    patient.laboratories << create(:laboratory, result: 'positive')
    assert_not patient.valid?(:api_create)

    patient.laboratories << create(:laboratory, result: 'positive', specimen_collection: 1.day.ago)
    assert patient.valid?(:api_create)
  end

  test 'ten_day_quarantine_candidates scope checks purged, monitoring, isolation, and continuous_exposure' do
    # Monitoring check
    patient = create(:patient, monitoring: true, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, monitoring: false, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # Purged check
    patient = create(:patient, purged: false, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, purged: true, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # Isolation check
    patient = create(:patient, isolation: false, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, isolation: true, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # Continuous exposure check
    patient = create(:patient, continuous_exposure: false, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, continuous_exposure: true, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'ten_day_quarantine_candidates scope has correct time range based on LDE' do
    # LDE + 9 days: too early
    patient = create(:patient, last_date_of_exposure: 9.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # LDE + 10 days: in range
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 11 days: in range
    patient = create(:patient, last_date_of_exposure: 11.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 12 days: in range
    patient = create(:patient, last_date_of_exposure: 12.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 13 days: in range
    patient = create(:patient, last_date_of_exposure: 13.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 14 days: in range as long as assessments are in range
    patient = create(:patient, last_date_of_exposure: 14.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: 1.day.ago)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 15 days: in range as long as assessments are in range
    patient = create(:patient, last_date_of_exposure: 15.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: 2.day.ago)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?
  end

  test 'ten_day_quarantine_candidates scope asserts no symptomatic assessments' do
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date, latest_assessment_at: DateTime.now.utc)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date, latest_assessment_at: DateTime.now.utc)
    # NOTE: Must test with multiple assessments where some are NOT symptomatic
    create(:assessment, patient_id: patient.id, symptomatic: true)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'ten_day_quarantine_candidates scope asserts assessments submitted in time range based on LDE' do
    # LDE + 9 days: too early
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: 1.day.ago.utc)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # LDE + 10 days: in range
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 11 days: in range
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 1.day)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 12 days: in range
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 2.day)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 13 days: in range
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 3.day)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 1 days: too late
    patient = create(:patient, last_date_of_exposure: 10.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 4.day)
    scoped_patients = Patient.ten_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'seven_day_quarantine_candidates scope checks purged, monitoring, isolation, and continuous_exposure' do
    # Monitoring check
    patient = create(:patient, monitoring: true, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, monitoring: false, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # Purged check
    patient = create(:patient, purged: false, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, purged: true, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # Isolation check
    patient = create(:patient, isolation: false, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, isolation: true, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # Continuous exposure check
    patient = create(:patient, continuous_exposure: false, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, continuous_exposure: true, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'seven_day_quarantine_candidates scope has correct time range based on LDE' do
    # LDE + 6 days: too early
    patient = create(:patient, last_date_of_exposure: 6.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # LDE + 7 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 8 days: in range
    patient = create(:patient, last_date_of_exposure: 8.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 9 days: in range
    patient = create(:patient, last_date_of_exposure: 9.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 11 days: in range as long as assessments and specimen collection are in range
    patient = create(:patient, last_date_of_exposure: 11.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: 3.days.ago)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: 3.days.ago.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # LDE + 12 days: in range as long as assessments and specimen collection are in range
    patient = create(:patient, last_date_of_exposure: 12.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: 3.days.ago)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: 3.days.ago.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?
  end

  test 'seven_day_quarantine_candidates scope asserts no symptomatic assessments' do
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    # NOTE: Must test with multiple assessments where some are NOT symptomatic
    create(:assessment, patient_id: patient.id, symptomatic: true)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'seven_day_quarantine_candidates scope asserts assessments submitted in time range based on LDE' do
    # LDE + 6 days: too early
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: 1.day.ago.utc)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # LDE + 7 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # # LDE + 8 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 1.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # # LDE + 9 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 2.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # # LDE + 10 days: too late
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 3.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'seven_day_quarantine_candidates scope asserts must be at least one negative lab test in range' do
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # If there is a negative PCR or ANTIGEN test it should still be true even if there are positive tests
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # If there is NO negative PCR or ANTIGEN test, can't pass
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'positive', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'seven_day_quarantine_candidates scope asserts only PCR or ANTIGEN lab tests' do
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'Antigen', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'Other', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'seven_day_quarantine_candidates scope asserts lab results specimen_collection within correct range around LDE' do
    # LDE + 4 days: too early
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: 1.day.ago.utc)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: 3.days.ago.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # LDE + 5 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: 2.days.ago)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # # LDE + 6 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 1.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: 1.day.ago)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # # LDE + 7 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 2.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    # # LDE + 8 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 3.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date + 1.day)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # LDE + 9 days: in range
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 3.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date + 2.days)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?

    # LDE + 10 days: too late
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false, created_at: DateTime.now.utc + 3.day)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'PCR', specimen_collection: DateTime.now.utc.to_date + 3.days)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert_not scoped_patients.where(id: patient.id).present?
  end

  test 'last assessment reminder sent eligible' do
    patient = create(:patient)
    assert patient.last_assessment_reminder_sent_eligible?

    patient.update(last_assessment_reminder_sent: 13.hours.ago)
    assert patient.last_assessment_reminder_sent_eligible?

    patient.update(last_assessment_reminder_sent: 11.hours.ago)
    assert_not patient.last_assessment_reminder_sent_eligible?
  end

  test 'update handles monitoring change' do
    patient = create(:patient, continuous_exposure: true, monitoring: true, closed_at: nil)
    assert patient.update({ monitoring: false })
    assert_not patient.monitoring
    assert_not patient.continuous_exposure
    assert_not_nil patient.closed_at
  end

  test 'update handles workflow change' do
    patient = create(:patient,
                     isolation: true,
                     extended_isolation: DateTime.now + 1.day,
                     user_defined_symptom_onset: true,
                     symptom_onset: DateTime.now - 1.day)
    earliest_symptomatic_assessment_timestamp = DateTime.now - 2.days
    create(:assessment, patient_id: patient.id, symptomatic: true, created_at: earliest_symptomatic_assessment_timestamp)
    patient.update({ isolation: false })
    assert_not patient.isolation
    assert_nil patient.extended_isolation
    assert_not patient.user_defined_symptom_onset
    assert_equal earliest_symptomatic_assessment_timestamp.to_date, patient.symptom_onset
  end

  test 'update handles case_status change' do
    patient = create(:patient, public_health_action: 'Recommended medical evaluation of symptoms')
    patient.update({ case_status: 'Unknown' })
    assert_equal 'Unknown', patient.case_status
    assert_equal 'None', patient.public_health_action
  end

  test 'update handles symptom_onset change' do
    patient = create(:patient, symptom_onset: DateTime.now - 1.day, user_defined_symptom_onset: false)
    earliest_symptomatic_assessment_timestamp = DateTime.now - 2.days
    create(:assessment, patient_id: patient.id, symptomatic: true, created_at: earliest_symptomatic_assessment_timestamp)
    patient.update({ symptom_onset: nil })
    assert_equal earliest_symptomatic_assessment_timestamp.to_date, patient.symptom_onset
    assert_not patient.user_defined_symptom_onset
  end

  test 'update handles continuous_exposure change' do
    patient = create(:patient, monitoring: false, continuous_exposure: false)
    patient.update({ continuous_exposure: true })
    # This update is not allowed when monitoring is false
    assert_not patient.continuous_exposure

    # But when monitoring is set to true, the update is allowed
    patient.update({ monitoring: true, continuous_exposure: true })
    assert patient.continuous_exposure
  end

  # monitoring_history_edit tests
  test 'monitoring_history_edit handles monitoring change' do
    patient = create(:patient, monitoring: false, continuous_exposure: false)
    history_data = {
      patient_before: { monitoring: true, continuous_exposure: true },
      updates: { monitoring: false },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient)
    assert_match(/Continuous Exposure/, h.find_by(created_by: 'Sara Alert System').comment)
    assert_match(/"Monitoring" to "Not Monitoring"/, h.find_by(history_type: 'Monitoring Change').comment)
  end

  test 'monitoring_history_edit handles exposure_risk_assessment change' do
    patient = create(:patient, exposure_risk_assessment: 'Low')
    history_data = {
      patient_before: { exposure_risk_assessment: 'High' },
      updates: { exposure_risk_assessment: 'Low' },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Exposure Risk Assessment.*"High".*"Low"/, h.comment)
  end

  test 'monitoring_history_edit handles monitoring_plan change' do
    patient = create(:patient, monitoring_plan: 'None')
    history_data = {
      patient_before: { monitoring_plan: 'Daily active monitoring' },
      updates: { monitoring_plan: 'None' },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Monitoring Plan.*"Daily active monitoring".*"None"/, h.comment)
  end

  test 'monitoring_history_edit handles public_health_action change' do
    patient = create(:patient, public_health_action: 'None')
    history_data = {
      patient_before: { public_health_action: 'Recommended laboratory testing' },
      updates: { public_health_action: 'None' },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Latest Public Health Action.*"Recommended laboratory testing".*"None"/, h.comment)
  end

  test 'monitoring_history_edit handles assigned_user change' do
    patient = create(:patient, assigned_user: 2)
    history_data = {
      patient_before: { assigned_user: 1 },
      updates: { assigned_user: 2 },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Assigned User.*"1".*"2"/, h.comment)
  end

  test 'monitoring_history_edit handles pause_notifications change' do
    patient = create(:patient, pause_notifications: false)
    history_data = {
      patient_before: { pause_notifications: true },
      updates: { pause_notifications: false },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/resumed notifications/, h.comment)
  end

  test 'monitoring_history_edit handles last_date_of_exposure change' do
    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    history_data = {
      patient_before: { last_date_of_exposure: 6.days.ago.utc.to_date },
      updates: { last_date_of_exposure: 7.days.ago.utc.to_date },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Last Date of Exposure/, h.comment)
  end

  test 'monitoring_history_edit handles continuous_exposure change' do
    patient = create(:patient, continuous_exposure: false)
    history_data = {
      patient_before: { continuous_exposure: true },
      updates: { continuous_exposure: false },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Continuous Exposure/, h.comment)
  end

  test 'monitoring_history_edit handles isolation change' do
    patient = create(:patient, isolation: false, extended_isolation: nil, symptom_onset: 6.days.ago.utc.to_date)
    history_data = {
      patient_before: { isolation: true, extended_isolation: 2.days.from_now.utc.to_date, symptom_onset: 6.days.ago.utc.to_date },
      updates: { isolation: false },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient)
    assert_match(/cleared Extended Isolation Date/, h.first.comment)
    assert_match(/changed Symptom Onset Date/, h.second.comment)
  end

  test 'monitoring_history_edit handles symptom_onset change' do
    patient = create(:patient, symptom_onset: 6.days.ago.utc.to_date)
    history_data = {
      patient_before: { symptom_onset: 7.days.ago.utc.to_date },
      updates: { symptom_onset: 6.days.ago.utc.to_date },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Symptom Onset/, h.comment)
  end

  test 'monitoring_history_edit handles case_status change' do
    patient = create(:patient, case_status: 'Unknown', public_health_action: 'None')
    history_data = {
      patient_before: { case_status: 'Confirmed', public_health_action: 'Recommended laboratory testing' },
      updates: { case_status: 'Unknown' },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient)
    assert_match(/Case Status.*"Confirmed".*"Unknown"/, h.first.comment)
    assert_match(/Latest Public Health Action.*"Recommended laboratory testing".*"None"/, h.second.comment)
  end

  test 'monitoring_history_edit handles case_status change with isolation change' do
    patient = create(:patient, case_status: 'Unknown', public_health_action: 'None', isolation: false)
    history_data = {
      patient_before: { case_status: 'Confirmed', isolation: true, public_health_action: 'Recommended laboratory testing' },
      updates: { isolation: false, case_status: 'Unknown' },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient)
    assert_match(/Case Status.*"Confirmed".*"Unknown"/, h.first.comment)
    assert_match(/Latest Public Health Action.*"Recommended laboratory testing".*"None"/, h.second.comment)
    # Symptom onset message must come after case status message
    assert_match(/isolation to exposure/, h.third.comment)
  end

  test 'monitoring_history_edit handles jurisdiction_id change' do
    patient = create(:patient, jurisdiction_id: 2)
    history_data = {
      patient_before: { jurisdiction_id: 1 },
      updates: { jurisdiction_id: 2 },
      patient: patient
    }
    patient.monitoring_history_edit(history_data, nil)
    h = History.where(patient: patient).first
    assert_match(/Jurisdiction/, h.comment)
  end

  test 'timezone offset' do
    patient = create(:patient)
    # Timezone defaults to Eastern
    assert_equal('America/New_York', patient.time_zone)
    # Should set on update on monitored_address_state
    patient.update(monitored_address_state: 'Minnesota')
    patient.reload
    assert_equal('America/Chicago', patient.time_zone)
    # Should set on update on address_state
    patient.update(monitored_address_state: nil, address_state: 'Montana')
    patient.reload
    assert_equal('America/Denver', patient.time_zone)
    # monitored should take precendence over normal address
    patient.update(monitored_address_state: 'Minnesota')
    patient.reload
    assert_equal('America/Chicago', patient.time_zone)
    # should default back to Eastern
    patient.update(monitored_address_state: nil, address_state: nil)
    patient.reload
    assert_equal('America/New_York', patient.time_zone)
  end

  test 'within preferred contact time scope utc' do
    patient = create(:patient, monitored_address_state: 'florida', preferred_contact_time: nil)
    # Production system will run in UTC
    # Before window
    Timecop.freeze((Time.now.utc).change(hour: 13)) do
      assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
    end
    # During window
    Timecop.freeze((Time.now.utc).change(hour: 17)) do
      assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
    end
    # After window
    Timecop.freeze((Time.now.utc).change(hour: 23)) do
      assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
    end
    Timecop.return
  end

  test 'within_preferred_contact_time scope' do
    patient = create(:patient)
    [
      { monitored_address_state: nil, address_state: nil },
      { monitored_address_state: 'Minnesota', address_state: nil },
      { monitored_address_state: nil, address_state: 'Minnesota' },
      { monitored_address_state: 'Montana', address_state: nil },
      { monitored_address_state: nil, address_state: 'Florida' }
    ].each do |state_params|
      patient.update(state_params)
      patient.update(preferred_contact_time: nil)
      patient.reload

      # default time window is 1200 - 1659
      # before window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 11, min: 59)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # front edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 12)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # middle of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 13)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # back edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 16, min: 59)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # after window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 17)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end

      # morning time window is 0800 - 1259
      patient.update(preferred_contact_time: 'Morning')
      patient.reload
      # before window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 7, min: 59)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # front edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 8)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # middle of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 10)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # back edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 12, min: 59)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # after window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 13)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end

      # afternoon time window is 1200 - 1659
      patient.update(preferred_contact_time: 'Afternoon')
      patient.reload
      # before window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 11, min: 59)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # front edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 12)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # middle of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 13)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # back edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 16, min: 59)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # after window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 17)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end

      # evening time window is 1600 - 1959
      patient.update(preferred_contact_time: 'Evening')
      patient.reload
      # before window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 15, min: 59)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # front edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 16)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # middle of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 17)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # back edge of window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 19, min: 59)) do
        assert_not_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
      # after window
      Timecop.freeze(Time.now.getlocal(patient.address_timezone_offset).change(hour: 20)) do
        assert_nil Patient.within_preferred_contact_time.find_by(id: patient.id)
      end
    end
    Timecop.return
  end

  test 'has_not_reported_recently scope' do
    # Example: 1 day reporting period => was patient last assessment before midnight today?
    # Example: 2 day reporting period => was patient last assessment before midnight yesterday?
    # Example: 7 day reporting period => was patient last assessment before midnight 6 days ago?
    original_reporting_period = ADMIN_OPTIONS['reporting_period_minutes']
    [
      1440,
      1440 * 2,
      1440 * 7,
      1440 * 21
    ].each do |reporting_period|
      ADMIN_OPTIONS['reporting_period_minutes'] = reporting_period
      [
        { monitored_address_state: nil, address_state: nil },
        { monitored_address_state: 'california', address_state: nil },
        { monitored_address_state: nil, address_state: 'minnesota' },
        { monitored_address_state: 'montana', address_state: nil },
        { monitored_address_state: nil, address_state: 'florida' }
      ].each do |state_params|
        patient = create(:patient, state_params)
        # Patient with no reports (latest_report_at is NULL)
        assert_not_nil Patient.has_not_reported_recently.find_by(id: patient.id)

        # Report outside of window
        create(:assessment, patient: patient, created_at: 30.days.ago)
        patient.reload
        assert_not_nil Patient.has_not_reported_recently.find_by(id: patient.id)

        # Report on right before start of window (23:59:59)
        assessment_2 = create(
          :assessment,
          patient: patient,
          created_at: correct_dst_edge(
            patient,
            Time.now.getlocal(patient.address_timezone_offset).end_of_day - ADMIN_OPTIONS['reporting_period_minutes'].minutes
          )
        )
        patient.reload
        assert_not_nil Patient.has_not_reported_recently.find_by(id: patient.id)

        # Report on front edge of window (00:00:00)
        assessment_2.update(
          created_at: correct_dst_edge(
            patient,
            Time.now.getlocal(patient.address_timezone_offset).end_of_day - ADMIN_OPTIONS['reporting_period_minutes'].minutes + 1.second
          )
        )
        assessment_2.reload
        patient.reload
        assert_nil Patient.has_not_reported_recently.find_by(id: patient.id)

        # Report inside of window
        assessment_2.update(created_at: Time.now.getlocal(patient.address_timezone_offset))
        assessment_2.reload
        patient.reload
        assert_nil Patient.has_not_reported_recently.find_by(id: patient.id)
      end
    end
    ADMIN_OPTIONS['reporting_period_minutes'] = original_reporting_period
  end

  test 'is_being_monitored scope' do
    original_monitoring_period = ADMIN_OPTIONS['monitoring_period_days']
    [
      14,
      21,
      60
    ].each do |monitoring_period|
      ADMIN_OPTIONS['monitoring_period_days'] = monitoring_period
      [
        { monitored_address_state: nil, address_state: nil },
        { monitored_address_state: 'minnesota', address_state: nil },
        { monitored_address_state: nil, address_state: 'minnesota' },
        { monitored_address_state: 'montana', address_state: nil },
        { monitored_address_state: nil, address_state: 'florida' }
      ].each do |state_params|
        # Created now should be in the monitoring period
        patient = create(:patient, state_params)
        assert_not_nil Patient.is_being_monitored.find_by(id: patient.id)

        # Created at within monitoring period
        patient.update(created_at: Time.now.getlocal(patient.address_timezone_offset) - 4.days)
        patient.reload
        assert_not_nil Patient.is_being_monitored.find_by(id: patient.id)

        # Created at on edge of monitoring period
        patient.update(created_at: Time.now.getlocal(patient.address_timezone_offset) - monitoring_period.days)
        patient.reload
        assert_not_nil Patient.is_being_monitored.find_by(id: patient.id)

        # Created at before monitoring period
        patient.update(created_at: Time.now.getlocal(patient.address_timezone_offset) - monitoring_period.days - 1.day)
        patient.reload
        assert_nil Patient.is_being_monitored.find_by(id: patient.id)

        # Exposure date today within monitoring period
        patient.update(last_date_of_exposure: Time.now.getlocal(patient.address_timezone_offset) - 4.days)
        patient.reload
        assert_not_nil Patient.is_being_monitored.find_by(id: patient.id)

        # Exposure date on edge of monitoring period
        patient.update(last_date_of_exposure: Time.now.getlocal(patient.address_timezone_offset) - monitoring_period.days)
        patient.reload
        assert_not_nil Patient.is_being_monitored.find_by(id: patient.id)

        # Exposure date before monitoring period
        patient.update(last_date_of_exposure: Time.now.getlocal(patient.address_timezone_offset) - monitoring_period.days - 1.day)
        patient.reload
        assert_nil Patient.is_being_monitored.find_by(id: patient.id)
      end
    end
    ADMIN_OPTIONS['monitoring_period_days'] = original_monitoring_period
  end

  test 'submitted_assessment_today scope' do
    [
      { monitored_address_state: nil, address_state: nil },
      { monitored_address_state: 'minnesota', address_state: nil },
      { monitored_address_state: nil, address_state: 'minnesota' },
      { monitored_address_state: 'montana', address_state: nil },
      { monitored_address_state: nil, address_state: 'florida' }
    ].each do |state_params|
      patient = create(:patient)
      patient.update(state_params)
      patient.reload

      # assessment is 3 days before
      assessment = create(:assessment, patient: patient)
      assessment.update(created_at: 3.days.ago)
      assessment.reload
      patient.reload
      assert_nil Patient.submitted_assessment_today.find_by(id: patient.id)

      # assessment is 11:59 PM day before
      yesterday_local = Time.now.getlocal(patient.address_timezone_offset) - 1.day
      assessment.update(created_at: correct_dst_edge(patient, yesterday_local.change(hour: 23, min: 59)))
      assessment.reload
      patient.reload
      assert_nil Patient.submitted_assessment_today.find_by(id: patient.id)

      # assessment is 12:00 AM current day
      assessment.update(
        created_at: correct_dst_edge(patient, Time.now.getlocal(patient.address_timezone_offset).change(hour: 0, min: 0))
      )
      assessment.reload
      patient.reload
      assert_not_nil Patient.submitted_assessment_today.find_by(id: patient.id)

      # assessment is 12:00 PM current day
      assessment.update(created_at: Time.now.getlocal(patient.address_timezone_offset).change(hour: 12))
      assessment.reload
      patient.reload
      assert_not_nil Patient.submitted_assessment_today.find_by(id: patient.id)

      # assessment is 11:59 PM current day
      assessment.update(created_at: Time.now.getlocal(patient.address_timezone_offset).change(hour: 23, min: 59))
      assessment.reload
      patient.reload
      assert_not_nil Patient.submitted_assessment_today.find_by(id: patient.id)

      # assessment is 12:00 AM next day
      assessment.update(created_at: Time.now.getlocal(patient.address_timezone_offset).change(hour: 0, min: 0) + 1.day)
      assessment.reload
      patient.reload
      assert_nil Patient.submitted_assessment_today.find_by(id: patient.id)

      # assessment is 9:00 AM next day
      assessment.update(created_at: Time.now.getlocal(patient.address_timezone_offset).change(hour: 9, min: 0) + 1.day)
      assessment.reload
      patient.reload
      assert_nil Patient.submitted_assessment_today.find_by(id: patient.id)
    end
  end

  test 'end_of_monitoring_period scope' do
    original_monitoring_period = ADMIN_OPTIONS['monitoring_period_days']
    [
      14,
      21,
      60
    ].each do |monitoring_period|
      ADMIN_OPTIONS['monitoring_period_days'] = monitoring_period
      [
        { monitored_address_state: nil, address_state: nil },
        { monitored_address_state: 'minnesota', address_state: nil },
        { monitored_address_state: nil, address_state: 'minnesota' },
        { monitored_address_state: 'montana', address_state: nil },
        { monitored_address_state: nil, address_state: 'florida' }
      ].each do |state_params|
        # Created now should be in the monitoring period
        patient = create(:patient, state_params)
        assert_nil Patient.end_of_monitoring_period.find_by(id: patient.id)

        # Created at within monitoring period
        patient.update(created_at: Time.now.getlocal(patient.address_timezone_offset) - 4.days)
        patient.reload
        assert_nil Patient.end_of_monitoring_period.find_by(id: patient.id)

        # Created at on edge of monitoring period
        edge_of_period = Time.now.getlocal(patient.address_timezone_offset) - monitoring_period.days
        patient.update(created_at: edge_of_period.change(hour: 0, min: 0))
        patient.reload
        assert_not_nil Patient.end_of_monitoring_period.find_by(id: patient.id)

        # Created at before monitoring period
        patient.update(created_at: edge_of_period - 1.day)
        patient.reload
        assert_not_nil Patient.end_of_monitoring_period.find_by(id: patient.id)

        # Exposure date today within monitoring period
        patient.update(last_date_of_exposure: Time.now.getlocal(patient.address_timezone_offset) - 4.days)
        patient.reload
        assert_nil Patient.end_of_monitoring_period.find_by(id: patient.id)

        # Exposure date on edge of monitoring period
        patient.update(last_date_of_exposure: edge_of_period)
        patient.reload
        assert_not_nil Patient.end_of_monitoring_period.find_by(id: patient.id)

        # Exposure date before monitoring period
        patient.update(last_date_of_exposure: edge_of_period - 1.day)
        patient.reload
        assert_not_nil Patient.end_of_monitoring_period.find_by(id: patient.id)
      end
    end
    ADMIN_OPTIONS['monitoring_period_days'] = original_monitoring_period
  end

  test 'has_usable_preferred_contact_method scope' do
    patient = create(:patient)

    # eligible contact methods
    ['E-mailed Web Link', 'SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].each do |contact_method|
      patient.update(preferred_contact_method: contact_method)
      patient.reload
      assert_not_nil Patient.has_usable_preferred_contact_method.find_by(id: patient.id)
    end
    # not eligible contact methods
    ['Unknown', 'Opt-out', '', nil].each do |contact_method|
      patient.update(preferred_contact_method: contact_method)
      patient.reload
      assert_nil Patient.has_usable_preferred_contact_method.find_by(id: patient.id)
    end
  end

  test 'reminder_not_sent_recently scope' do
    # Example: 1 day reporting period => was patient last assessment before midnight today?
    # Example: 2 day reporting period => was patient last assessment before midnight yesterday?
    # Example: 7 day reporting period => was patient last assessment before midnight 6 days ago?
    original_reporting_period = ADMIN_OPTIONS['reporting_period_minutes']
    [
      1440,
      1440 * 2,
      1440 * 7,
      1440 * 21
    ].each do |reporting_period|
      ADMIN_OPTIONS['reporting_period_minutes'] = reporting_period
      [
        { monitored_address_state: nil, address_state: nil },
        { monitored_address_state: 'california', address_state: nil },
        { monitored_address_state: nil, address_state: 'minnesota' },
        { monitored_address_state: 'montana', address_state: nil },
        { monitored_address_state: nil, address_state: 'florida' }
      ].each do |state_params|
        patient = create(:patient, state_params)
        # Patient with no reports (latest_report_at is NULL)
        assert_not_nil Patient.reminder_not_sent_recently.find_by(id: patient.id)

        # Report outside of window
        patient.update(last_assessment_reminder_sent: 30.days.ago)
        patient.reload
        assert_not_nil Patient.reminder_not_sent_recently.find_by(id: patient.id)

        # Report on right before start of window (23:59:59)
        last_reminder = correct_dst_edge(
          patient,
          Time.now.getlocal(patient.address_timezone_offset).end_of_day - ADMIN_OPTIONS['reporting_period_minutes'].minutes
        )
        patient.update(
          last_assessment_reminder_sent: last_reminder
        )
        patient.reload
        assert_not_nil Patient.reminder_not_sent_recently.find_by(id: patient.id)

        # Report on front edge of window (00:00:00)
        patient.update(last_assessment_reminder_sent: last_reminder + 1.second)
        patient.reload
        assert_nil Patient.reminder_not_sent_recently.find_by(id: patient.id)

        # Report inside of window
        patient.update(last_assessment_reminder_sent: Time.now.getlocal(patient.address_timezone_offset))
        patient.reload
        assert_nil Patient.reminder_not_sent_recently.find_by(id: patient.id)
      end
    end
    ADMIN_OPTIONS['reporting_period_minutes'] = original_reporting_period
  end

  test 'no_recent_activity reason in close_eligible scope' do
    patient = create(:patient, isolation: false, monitoring: true, created_at: 100.days.ago)

    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 1.day.ago)
    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 5.days.ago)
    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 10.days.ago)
    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 20.days.ago)
    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 29.days.ago)
    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 30.days.ago)
    assert_not_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 31.days.ago)
    assert_not_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(updated_at: 300.days.ago)
    assert_not_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(isolation: true)
    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)

    patient.update(isolation: false, monitoring: false)
    assert_nil Patient.close_eligible(:no_recent_activity).find_by(id: patient.id)
  end

  test 'invalid reason in close_eligible scope' do
    exception = assert_raises(Exception) { Patient.close_eligible(:fake_reason) }
    assert_includes(exception.message, 'Invalid reason provided to close_eligible scope!')
  end

  test 'completed_monitoring reason in close_eligible scope' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     last_date_of_exposure: 20.days.ago)
    assert_not_nil Patient.close_eligible(:completed_monitoring).find_by(id: patient.id)
  end

  test 'enrolled_last_day_monitoring_period reason in close_eligible scope' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     created_at: 20.days.ago)
    assert_not_nil Patient.close_eligible(:completed_monitoring).find_by(id: patient.id)
    assert_nil Patient.close_eligible(:enrolled_last_day_monitoring_period).find_by(id: patient.id)
    patient.update(last_date_of_exposure: Time.now.getlocal('-05:00') - 34.days)
    assert_not_nil Patient.close_eligible(:completed_monitoring).find_by(id: patient.id)
    assert_not_nil Patient.close_eligible(:enrolled_last_day_monitoring_period).find_by(id: patient.id)
  end

  test 'enrolled_past_monitioring_period reason in close_eligible scope' do
    patient = create(:patient,
                     purged: false,
                     isolation: false,
                     monitoring: true,
                     symptom_onset: nil,
                     public_health_action: 'None',
                     latest_assessment_at: Time.now,
                     created_at: 20.days.ago)
    assert_not_nil Patient.close_eligible(:completed_monitoring).find_by(id: patient.id)
    assert_nil Patient.close_eligible(:enrolled_past_monitioring_period).find_by(id: patient.id)
    assert_nil Patient.close_eligible(:enrolled_last_day_monitoring_period).find_by(id: patient.id)
    patient.update(last_date_of_exposure: Time.now.getlocal('-05:00') - 35.days)
    assert_not_nil Patient.close_eligible(:completed_monitoring).find_by(id: patient.id)
    assert_not_nil Patient.close_eligible(:enrolled_past_monitioring_period).find_by(id: patient.id)
    assert_nil Patient.close_eligible(:enrolled_last_day_monitoring_period).find_by(id: patient.id)
  end

  [
    { isolation: true },
    { isolation: false, monitoring: true, purged: false, public_health_action: 'Recommended medical evaluation of symptoms' },
    { isolation: false, monitoring: true, purged: true, public_health_action: 'None' },
    { isolation: false, monitoring: false, purged: false, public_health_action: 'None' },
    {
      isolation: false,
      monitoring: true,
      purged: false,
      public_health_action: 'Recommended medical evaluation of symptoms',
      latest_assessment_at: 400.days.ago
    },
    { isolation: false, monitoring: true, purged: true, public_health_action: 'None', latest_assessment_at: 400.days.ago },
    { isolation: false, monitoring: false, purged: false, public_health_action: 'None', latest_assessment_at: 400.days.ago }
  ].each do |invalid_attr|
    test "close_eligible scope ineligible due to #{invalid_attr}" do
      patient = create(:patient, invalid_attr)
      patient.update(created_at: 50.days.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      patient.update(updated_at: 1.day.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      patient.update(updated_at: 5.days.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      patient.update(updated_at: 10.days.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      patient.update(updated_at: 20.days.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      patient.update(updated_at: 29.days.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      # 30 day border is sensitive to DST changes
      patient.update(updated_at: correct_dst_edge(patient, 30.days.ago))
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      patient.update(updated_at: 31.days.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)

      patient.update(updated_at: 300.days.ago)
      assert_nil Patient.close_eligible.find_by(id: patient.id)
    end
  end

  test 'time_to_contact_next method' do
    morning_patient = create(:patient, preferred_contact_time: 'Morning')
    afternoon_patient = create(:patient, preferred_contact_time: 'Afternoon')
    evening_patient = create(:patient, preferred_contact_time: 'Evening')
    unspec_patient = create(:patient, preferred_contact_time: nil)

    patient_local_time = Time.now.getlocal(morning_patient.address_timezone_offset)

    # Current time is before any of the time windows
    Timecop.freeze(patient_local_time.change(hour: 5)) do
      # Hour check
      assert_equal morning_patient.time_to_contact_next.hour, 8
      assert_equal afternoon_patient.time_to_contact_next.hour, 12
      assert_equal evening_patient.time_to_contact_next.hour, 16
      assert_equal unspec_patient.time_to_contact_next.hour, 12
      # Day of month check
      assert_equal morning_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal afternoon_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal evening_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal unspec_patient.time_to_contact_next.day, patient_local_time.day
    end

    # Current time is within the morning window
    Timecop.freeze(patient_local_time.change(hour: 9)) do
      # Hour check
      assert_equal morning_patient.time_to_contact_next.hour, 9
      assert_equal afternoon_patient.time_to_contact_next.hour, 12
      assert_equal evening_patient.time_to_contact_next.hour, 16
      assert_equal unspec_patient.time_to_contact_next.hour, 12
      # Day of month check
      assert_equal morning_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal afternoon_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal evening_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal unspec_patient.time_to_contact_next.day, patient_local_time.day
    end

    # Current time is within the afternoon & unspecified windows
    Timecop.freeze(patient_local_time.change(hour: 14)) do
      # Hour check
      assert_equal morning_patient.time_to_contact_next.hour, 8
      assert_equal afternoon_patient.time_to_contact_next.hour, 14
      assert_equal evening_patient.time_to_contact_next.hour, 16
      assert_equal unspec_patient.time_to_contact_next.hour, 14
      # Day of month check
      assert_equal morning_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
      assert_equal afternoon_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal evening_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal unspec_patient.time_to_contact_next.day, patient_local_time.day
    end

    # Current time is within the evening window
    Timecop.freeze(patient_local_time.change(hour: 18)) do
      # Hour check
      assert_equal morning_patient.time_to_contact_next.hour, 8
      assert_equal afternoon_patient.time_to_contact_next.hour, 12
      assert_equal evening_patient.time_to_contact_next.hour, 18
      assert_equal unspec_patient.time_to_contact_next.hour, 12
      # Day of month check
      assert_equal morning_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
      assert_equal afternoon_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
      assert_equal evening_patient.time_to_contact_next.day, patient_local_time.day
      assert_equal unspec_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
    end

    # Current time after all windows for the day
    Timecop.freeze(patient_local_time.change(hour: 21)) do
      # Hour check
      assert_equal morning_patient.time_to_contact_next.hour, 8
      assert_equal afternoon_patient.time_to_contact_next.hour, 12
      assert_equal evening_patient.time_to_contact_next.hour, 16
      assert_equal unspec_patient.time_to_contact_next.hour, 12
      # Day of month check
      assert_equal morning_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
      assert_equal afternoon_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
      assert_equal evening_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
      assert_equal unspec_patient.time_to_contact_next.day, patient_local_time.tomorrow.day
    end
  end

  test 'time_to_notify_closed method' do
    morning_patient = create(:patient, preferred_contact_time: 'Morning')
    afternoon_patient = create(:patient, preferred_contact_time: 'Afternoon')
    evening_patient = create(:patient, preferred_contact_time: 'Evening')
    unspec_patient = create(:patient, preferred_contact_time: nil)

    patient_local_time = Time.now.getlocal(morning_patient.address_timezone_offset)

    # Current time is before 8am
    Timecop.freeze(patient_local_time.change(hour: 5)) do
      # Hour check
      assert_equal morning_patient.time_to_notify_closed.hour, 8
      assert_equal afternoon_patient.time_to_notify_closed.hour, 8
      assert_equal evening_patient.time_to_notify_closed.hour, 8
      assert_equal unspec_patient.time_to_notify_closed.hour, 8
      # Day of month check
      assert_equal morning_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal afternoon_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal evening_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal unspec_patient.time_to_notify_closed.day, patient_local_time.day
    end

    # Current time is within 8am - 8pm
    Timecop.freeze(patient_local_time.change(hour: 8)) do
      # Hour check
      assert_equal morning_patient.time_to_notify_closed.hour, 8
      assert_equal afternoon_patient.time_to_notify_closed.hour, 8
      assert_equal evening_patient.time_to_notify_closed.hour, 8
      assert_equal unspec_patient.time_to_notify_closed.hour, 8
      # Day of month check
      assert_equal morning_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal afternoon_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal evening_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal unspec_patient.time_to_notify_closed.day, patient_local_time.day
    end

    # Current time is within 8am - 8pm
    Timecop.freeze(patient_local_time.change(hour: 13)) do
      # Hour check
      assert_equal morning_patient.time_to_notify_closed.hour, 13
      assert_equal afternoon_patient.time_to_notify_closed.hour, 13
      assert_equal evening_patient.time_to_notify_closed.hour, 13
      assert_equal unspec_patient.time_to_notify_closed.hour, 13
      # Day of month check
      assert_equal morning_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal afternoon_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal evening_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal unspec_patient.time_to_notify_closed.day, patient_local_time.day
    end

    # Current time is within 8am - 8pm
    Timecop.freeze(patient_local_time.change(hour: 19)) do
      # Hour check
      assert_equal morning_patient.time_to_notify_closed.hour, 19
      assert_equal afternoon_patient.time_to_notify_closed.hour, 19
      assert_equal evening_patient.time_to_notify_closed.hour, 19
      assert_equal unspec_patient.time_to_notify_closed.hour, 19
      # Day of month check
      assert_equal morning_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal afternoon_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal evening_patient.time_to_notify_closed.day, patient_local_time.day
      assert_equal unspec_patient.time_to_notify_closed.day, patient_local_time.day
    end

    # Current time after all windows for the day
    Timecop.freeze(patient_local_time.change(hour: 20)) do
      # Hour check
      assert_equal morning_patient.time_to_notify_closed.hour, 8
      assert_equal afternoon_patient.time_to_notify_closed.hour, 8
      assert_equal evening_patient.time_to_notify_closed.hour, 8
      assert_equal unspec_patient.time_to_notify_closed.hour, 8
      # Day of month check
      assert_equal morning_patient.time_to_notify_closed.day, patient_local_time.tomorrow.day
      assert_equal afternoon_patient.time_to_notify_closed.day, patient_local_time.tomorrow.day
      assert_equal evening_patient.time_to_notify_closed.day, patient_local_time.tomorrow.day
      assert_equal unspec_patient.time_to_notify_closed.day, patient_local_time.tomorrow.day
    end
  end
end
# rubocop:enable Metrics/ClassLength

# Inheriting PatientTest and overriding setup
# allows us to run the same exact tests but change the Timecop time that
# the tests are running at
class PatientTestWhenDSTStarts < PatientTest
  def setup
    super
    Timecop.freeze(Time.parse('2021-03-14T18:00:00Z'))
  end

  def teardown
    super
    Timecop.return
  end
end

class PatientTestWhenDSTEnds < PatientTest
  def setup
    super
    Timecop.freeze(Time.parse('2021-11-07T18:00:00Z'))
  end

  def teardown
    super
    Timecop.return
  end
end
