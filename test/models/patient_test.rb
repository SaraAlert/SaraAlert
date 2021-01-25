# frozen_string_literal: true

require 'test_case'

# rubocop:disable Metrics/ClassLength
class PatientTest < ActiveSupport::TestCase
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
                     preferred_contact_method: 'Telephone call')

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call')

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records with paused notifications' do
    patient = create(:patient,
                     purged: false,
                     pause_notifications: true,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call')

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call')

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
                     preferred_contact_method: 'Telephone call')

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records that report through a HoH' do
    responder = create(:patient,
                       purged: false,
                       pause_notifications: false,
                       monitoring: true,
                       preferred_contact_method: 'Telephone call')

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call')

    patient.update!(responder_id: responder.id)
    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call')

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records have received an assessment reminder in the last 12 hours' do
    # Assessment was sent more than 12 hours ago - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     last_assessment_reminder_sent: 13.hours.ago)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was not sent (nil) - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     last_assessment_reminder_sent: nil)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was sent exactly 12 hours ago - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     last_assessment_reminder_sent: 12.hours.ago)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was sent under 10 hours - should NOT be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     last_assessment_reminder_sent: 10.hours.ago)

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'reminder eligible does not include records that have completed an assessment today' do
    # Assessment was completed more than a day ago - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     latest_assessment_at: 25.hours.ago)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was not completed (nil) - should be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     latest_assessment_at: nil)

    assert_equal(1, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was completed at the very beginning of the day - should NOT be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     latest_assessment_at: Time.now.in_time_zone('Eastern Time (US & Canada)').beginning_of_day)

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)

    # Assessment was completed now - should NOT be eligible
    patient = create(:patient,
                     purged: false,
                     pause_notifications: false,
                     monitoring: true,
                     preferred_contact_method: 'Telephone call',
                     latest_assessment_at: Time.now)

    assert_equal(0, Patient.reminder_eligible.where(id: patient.id).count)
  end

  test 'create patient' do
    assert patient = create(:patient)
    assert_nil patient.symptom_onset
    assert_nil patient.latest_assessment_at
    assert_nil patient.latest_fever_or_fever_reducer_at
    assert_empty patient.assessments
    assert_nil patient.latest_positive_lab_at
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

    patient = create(:patient, id: 100)
    patient.update(responder_id: 42)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'household'

    patient = create(:patient, preferred_contact_method: 'Unknown')
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'ineligible preferred contact method'

    patient = create(:patient, isolation: false, last_date_of_exposure: 30.days.ago, continuous_exposure: false, preferred_contact_method: 'Telephone call')
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'monitoring period has elapsed'

    patient = create(:patient, preferred_contact_method: 'Telephone call', last_assessment_reminder_sent: 1.hour.ago)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'contacted recently'

    patient = create(:patient, preferred_contact_method: 'Telephone call', latest_assessment_at: 1.hour.ago)
    assert_not patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? 'already reported'

    patient = create(:patient, preferred_contact_method: 'Telephone call', preferred_contact_time: 'Morning')
    assert patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? '8:00 AM local time (Morning)'

    patient = create(:patient, preferred_contact_method: 'Telephone call', preferred_contact_time: 'Afternoon')
    assert patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? '12:00 PM local time (Afternoon)'

    patient = create(:patient, preferred_contact_method: 'Telephone call', preferred_contact_time: 'Evening')
    assert patient.report_eligibility[:eligible]
    assert patient.report_eligibility[:messages].join(' ').include? '4:00 PM local time (Evening)'

    patient = create(:patient, preferred_contact_method: 'Telephone call')
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
    jur = Jurisdiction.create
    user = User.create!(
      email: 'foobar@example.com',
      password: '1234567ab!',
      jurisdiction: jur,
      force_password_change: true # Require user to change password on first login
    )
    Patient.destroy_all
    patient = Patient.new(creator: user, jurisdiction: jur)
    patient.responder = patient
    patient.save
    assert Patient.count == 1
    # Updated at of today, still monitoring, should not be purgeable
    assert Patient.purge_eligible.count.zero?
    patient.update!(monitoring: false)
    # Updated at of today, not monitoring, should not be purgeable
    assert Patient.purge_eligible.count.zero?
    # Updated at of 2x purgeable_after, not monitoring, should obviously be purgeable regardless of weekly_purge_date and weekly_purge_warning_date
    patient.update!(updated_at: (2 * ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # ADMIN_OPTIONS['weekly_purge_warning_date'] is 2.5 days before ADMIN_OPTIONS['weekly_purge_date']
    # Test if the email was going out in 1 minute and patient was updated purgeable_after minutes ago, patient should be purgeable
    # These tests reset the weekly_purge_warning_date and weekly_purge_date, and set the times to 1 minute from Time.now to avoid timing issues
    # caused by the duration of time it takes to run the test
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 2.5.days + 1.minute).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count == 1
    # However, if the test email was going out in 1 minute from now and the patient was last updated purgeable_after - 2 minutes ago, no purge
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 2.5.days + 1.minute).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] - 2).minutes.ago)
    assert Patient.purge_eligible.count.zero?
    # Now test the boundry conditions that exist between the purge_warning and the purging
    # ADMIN_OPTIONS['weekly_purge_warning_date'] is 2.5 days before ADMIN_OPTIONS['weekly_purge_date']
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    # If the email is going out in 1 minute, and the patient was modified purgeable_after minutes ago, they should not be purgeable
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.count.zero?
    # However, if the email is going out in 1 minute and the patient was modified right before the warning (2.5 days ago), they should be purgeable
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] + (2.5.days / 1.minute)).minutes.ago)
    # If the patient was modified right before the warning, but that was on a DST boundary, the comparison to minutes before will be off by 1 hour.
    if Time.use_zone('Eastern Time (US & Canada)') { (Time.now + 1.minute - 2.5.days).dst? }
      assert_equal Patient.purge_eligible.count, 0
    else
      assert_equal Patient.purge_eligible.count, 1
    end
    # Anything less than the 2.5 days ago means the patient was modified between the warning and the purging and should not be purged
    ADMIN_OPTIONS['weekly_purge_date'] = (Time.now + 1.minute).strftime('%A %l:%M%p')
    ADMIN_OPTIONS['weekly_purge_warning_date'] = (Time.now + 1.minute - 2.5.days).strftime('%A %l:%M%p')
    patient.update!(updated_at: (ADMIN_OPTIONS['purgeable_after'] + (2.5.days / 1.minute) - 2).minutes.ago)
    assert Patient.purge_eligible.count.zero?
  end

  test 'purge eligible continuous_exposure' do
    patient = create(:patient, purged: false, monitoring: false, continuous_exposure: true)
    patient.update!(updated_at: (2 * ADMIN_OPTIONS['purgeable_after']).minutes.ago)
    assert Patient.purge_eligible.size == 1
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

    # does not meet defiition: has positive test result more than 10 days ago, but also has positive test result less than 10 days ago
    laboratory_1 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 11.days.ago)
    laboratory_2 = create(:laboratory, patient: patient, result: 'positive', specimen_collection: 9.days.ago)
    verify_patient_status(patient, :isolation_non_reporting)
    laboratory_1.destroy
    laboratory_2.destroy

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
      preferred_contact_method: 'SMS Texted Weblink'
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
      preferred_contact_method: 'SMS Texted Weblink'
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
      preferred_contact_method: 'SMS Texted Weblink'
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
      preferred_contact_method: 'SMS Texted Weblink'
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
      preferred_contact_method: 'SMS Texted Weblink'
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
      preferred_contact_method: 'SMS Texted Weblink'
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

  test 'duplicate_data finds duplicate that matches all criteria' do
    patient_dup = Patient.first
    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth],
                                            patient_dup[:user_defined_id_statelocal])

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [
                   {
                     count: 1,
                     fields: ['First Name', 'Last Name', 'Sex', 'Date of Birth']
                   },
                   {
                     count: 1,
                     fields: ['State/Local ID']
                   }
                 ])
  end

  test 'duplicate_data finds duplicate that matches basic info fields' do
    patient_dup = Patient.first
    duplicate_data = Patient.duplicate_data(patient_dup[:first_name],
                                            patient_dup[:last_name],
                                            patient_dup[:sex],
                                            patient_dup[:date_of_birth],
                                            'test state/local ID')

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [{
                   count: 1,
                   fields: ['First Name', 'Last Name', 'Sex', 'Date of Birth']
                 }])
  end

  test 'duplicate_data finds duplicate that matches state/local id' do
    patient_dup = Patient.first
    duplicate_data = Patient.duplicate_data('test first name',
                                            'test last name',
                                            'test sex',
                                            Time.now,
                                            patient_dup[:user_defined_id_statelocal])

    assert duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [{
                   count: 1,
                   fields: ['State/Local ID']
                 }])
  end

  test 'duplicate_data correctly finds no duplicates' do
    duplicate_data = Patient.duplicate_data('test first name',
                                            'test last name',
                                            'test sex',
                                            Time.now,
                                            'test state/local ID')

    assert !duplicate_data[:is_duplicate]
    assert_equal(duplicate_data[:duplicate_field_data], [])
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

  test 'validates address_state inclusion in api context' do
    patient = valid_patient

    patient.address_state = 'Georgia'
    assert patient.valid?(:api)

    patient.address_state = 'foo'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates ethnicity inclusion in api context' do
    patient = valid_patient

    patient.ethnicity = 'Hispanic or Latino'
    assert patient.valid?(:api)

    patient.ethnicity = ''
    assert patient.valid?(:api)

    patient.ethnicity = nil
    assert patient.valid?(:api)

    patient.ethnicity = 'foo'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates monitored_address_state inclusion in api context' do
    patient = valid_patient

    patient.monitored_address_state = 'Oregon'
    assert patient.valid?(:api)

    patient.monitored_address_state = ''
    assert patient.valid?(:api)

    patient.monitored_address_state = nil
    assert patient.valid?(:api)

    patient.monitored_address_state = 'foo'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates preferred contact method inclusion in api context' do
    patient = valid_patient

    patient.preferred_contact_method = 'Unknown'
    assert patient.valid?(:api)

    patient.preferred_contact_method = ''
    assert patient.valid?(:api)

    patient.preferred_contact_method = nil
    assert patient.valid?(:api)

    patient.preferred_contact_method = 'foo'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates preferred contact time inclusion in api context' do
    patient = valid_patient

    patient.preferred_contact_time = 'Morning'
    assert patient.valid?(:api)

    patient.preferred_contact_time = ''
    assert patient.valid?(:api)

    patient.preferred_contact_time = nil
    assert patient.valid?(:api)

    patient.preferred_contact_time = 'foo'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates sex inclusion in api context' do
    patient = valid_patient

    patient.sex = 'Female'
    assert patient.valid?(:api)

    patient.sex = ''
    assert patient.valid?(:api)

    patient.sex = nil
    assert patient.valid?(:api)

    patient.sex = 'foo'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates primary phone is a possible phone number in api context' do
    patient = valid_patient

    patient.primary_telephone = '+11111111111'
    assert patient.valid?(:api)

    patient.primary_telephone = '+1 111 111 1111'
    assert patient.valid?(:api)

    patient.primary_telephone = ''
    assert patient.valid?(:api)

    patient.primary_telephone = nil
    assert patient.valid?(:api)

    patient.primary_telephone = '123'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates secondary phone is a possible phone number in api context' do
    patient = valid_patient

    patient.secondary_telephone = '+11111111111'
    assert patient.valid?(:api)

    patient.secondary_telephone = '+1 111 111 1111'
    assert patient.valid?(:api)

    patient.secondary_telephone = ''
    assert patient.valid?(:api)

    patient.secondary_telephone = nil
    assert patient.valid?(:api)

    patient.secondary_telephone = '123'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates date_of_birth is a valid date in api context' do
    patient = valid_patient

    patient.date_of_birth = 25.years.ago
    assert patient.valid?(:api)

    patient.date_of_birth = '01-15-2000'
    assert_not patient.valid?(:api)

    patient.date_of_birth = '2000-13-13'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates last_date_of_exposure is a valid date in api context' do
    patient = valid_patient

    patient.last_date_of_exposure = Time.now - 1.day
    assert patient.valid?(:api)

    patient.last_date_of_exposure = '01-15-2000'
    assert_not patient.valid?(:api)

    patient.last_date_of_exposure = '2000-13-13'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates symptom_onset is a valid date in api context' do
    patient = valid_patient

    patient.symptom_onset = Time.now - 1.day
    assert patient.valid?(:api)

    patient.symptom_onset = ''
    assert patient.valid?(:api)

    patient.symptom_onset = nil
    assert patient.valid?(:api)

    patient.symptom_onset = '01-15-2000'
    assert_not patient.valid?(:api)

    patient.symptom_onset = '2000-13-13'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates email is a valid email address in api context' do
    patient = valid_patient

    patient.email = 'foo@bar.com'
    assert patient.valid?(:api)

    patient.email = ''
    assert patient.valid?(:api)

    patient.email = nil
    assert patient.valid?(:api)

    patient.email = 'not@an@email.com'
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates address_state is required in api context' do
    patient = valid_patient

    assert patient.valid?(:api)

    patient.address_state = nil
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates date_of_birth is required in api context' do
    patient = valid_patient

    assert patient.valid?(:api)

    patient.date_of_birth = nil
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates first_name is required in api context' do
    patient = valid_patient

    assert patient.valid?(:api)

    patient.first_name = nil
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates last_name is required in api context' do
    patient = valid_patient

    assert patient.valid?(:api)

    patient.last_name = nil
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates email is not blank when preferred_contact_method is "E-mailed Web Link"' do
    patient = valid_patient

    patient.email = 'foo@bar.com'
    patient.preferred_contact_method = 'E-mailed Web Link'
    assert patient.valid?(:api)

    patient.email = ''
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates primary_telephone is not blank when preferred_contact_method requires a phone' do
    patient = valid_patient

    patient.primary_telephone = '+1111111111'
    patient.preferred_contact_method = 'SMS Text-message'
    assert patient.valid?(:api)

    patient.primary_telephone = ''
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates symptom_onset is present when isolation is true' do
    patient = valid_patient

    patient.isolation = false
    patient.symptom_onset = nil
    assert patient.valid?(:api)

    patient.isolation = true
    patient.symptom_onset = Time.now - 1.day
    assert patient.valid?(:api)

    patient.isolation = true
    patient.symptom_onset = nil
    assert_not patient.valid?(:api)
    assert patient.valid?
  end

  test 'validates last_date_of_exposure is present when isolation is false' do
    patient = valid_patient

    patient.isolation = true
    patient.last_date_of_exposure = nil
    assert patient.valid?(:api)

    patient.isolation = false
    patient.last_date_of_exposure = Time.now - 1.day
    assert patient.valid?(:api)

    patient.isolation = false
    patient.last_date_of_exposure = nil
    assert_not patient.valid?(:api)
    assert patient.valid?
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
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'ANTIGEN', specimen_collection: DateTime.now.utc.to_date)
    scoped_patients = Patient.seven_day_quarantine_candidates(DateTime.now.utc)
    assert scoped_patients.where(id: patient.id).present?

    patient = create(:patient, last_date_of_exposure: 7.days.ago.utc.to_date)
    create(:assessment, patient_id: patient.id, symptomatic: false)
    create(:laboratory, patient_id: patient.id, result: 'negative', lab_type: 'test', specimen_collection: DateTime.now.utc.to_date)
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
  
  test 'get_updates_from_monitoring_changes handles monitoring change' do
  end

  test 'get_updates_from_monitoring_changes handles workflow change' do
  end

  test 'get_updates_from_monitoring_changes handles symptom_onset change' do
  end

  test 'get_updates_from_monitoring_changes handles case_status change' do
  end

  test 'get_updates_from_monitoring_changes handles continuous_exposure change' do
  end
end
# rubocop:enable Metrics/ClassLength
