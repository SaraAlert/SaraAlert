# frozen_string_literal: true

require 'test_case'

class PurgeJobTest < ActiveSupport::TestCase
  def setup
    # Allowed to purge immediately for the tests
    ADMIN_OPTIONS['job_run_email'] = 'test@test.com'
    Patient.delete_all
    Assessment.delete_all
    ReportedCondition.delete_all
    Symptom.delete_all
  end

  def teardown
    ADMIN_OPTIONS['job_run_email'] = nil
  end

  test 'sends an email with all purged monitorees' do
    patient = create(:patient, monitoring: false, purged: false)
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'].minutes + 14.days).ago)
    email = PurgeJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, patient.id.to_s)
  end

  test 'sends an email with all non purged monitorees' do
    patient = create(:patient, monitoring: false, purged: false)
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'].minutes + 14.days).ago)

    allow_any_instance_of(Patient).to(receive(:update!) do
      raise StandardError, 'Test StandardError'
    end)

    email = PurgeJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, patient.id.to_s)
    assert_includes(email_body, 'Test StandardError')
  end

  test 'does not purge heads of household with active dependents' do
    patient = create(:patient, monitoring: false, purged: false, address_line_1: Faker::Alphanumeric.alphanumeric(number: 10))
    dependent = create(:patient, monitoring: true, responder_id: patient.id)
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'].minutes + 14.days).ago, dependents: patient.dependents << dependent)

    PurgeJob.perform_now
    patient.reload
    # Head of household was not purged; check for attributes that should not have been deleted
    assert(patient.address_line_1)
    # dependent has not been purged/reset monitoring
    assert(dependent.monitoring)
  end

  test 'cleans up downloads' do
    create(:patient, monitoring: false, purged: false)
    create(:download, created_at: 25.hours.ago)
    PurgeJob.perform_now
    assert(Download.count.zero?)
  end

  test 'cleans up assessment receipts' do
    create(:patient, monitoring: false, purged: false)
    create(:assessment_receipt, created_at: 25.hours.ago)
    PurgeJob.perform_now
    assert(AssessmentReceipt.count.zero?)
  end

  test 'cleans up symptoms, reported conditions, and assessments of purged patients' do
    patient = create(:patient, monitoring: false, purged: false)

    assessment = create(:assessment, patient: patient)
    reported_condition = create(:reported_condition, assessment: assessment)
    create(:symptom, condition_id: reported_condition.id)
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'].minutes + 14.days).ago)
    PurgeJob.perform_now
    assert(Assessment.count.zero?)
    assert(ReportedCondition.count.zero?)
    assert_equal(Symptom.count, 1)
    assert_equal(Symptom.first, patient.jurisdiction.threshold_conditions.first.symptoms.first)
  end

  test 'nils out everything but kept attributes' do
    patient = create(:patient, monitoring: false, purged: false, continuous_exposure: false, submission_token: 'a',
                               monitoring_reason: 'Other', exposure_risk_assessment: 'Low', monitoring_plan: 'None', public_health_action: 'None',
                               last_assessment_reminder_sent: 1.month.ago, user_defined_id_statelocal: '1', user_defined_id_cdc: '1',
                               user_defined_id_nndss: '1', first_name: 'a', last_name: 'a', date_of_birth: 1.year.ago, age: 1, sex: 'Unknown',
                               white: false, black_or_african_american: false, american_indian_or_alaska_native: false, asian: false,
                               native_hawaiian_or_other_pacific_islander: false, ethnicity: 'Hispanic or Latino', primary_language: 'a',
                               secondary_language: 'a', interpretation_required: false, nationality: 'a', address_line_1: 'a',
                               foreign_address_line_1: 'a', address_city: 'a', address_state: 'Texas', address_line_2: 'a', address_zip: 'a',
                               address_county: 'a', monitored_address_line_1: 'a', monitored_address_city: 'a', monitored_address_state: 'Texas',
                               monitored_address_line_2: 'a', monitored_address_zip: 'a', monitored_address_county: 'a',
                               foreign_address_city: 'a', foreign_address_country: 'a', foreign_address_line_2: 'a', foreign_address_zip: 'a',
                               foreign_address_line_3: 'a', foreign_address_state: 'a', foreign_monitored_address_line_1: 'a',
                               foreign_monitored_address_city: 'a', foreign_monitored_address_state: '', foreign_monitored_address_line_2: 'a',
                               foreign_monitored_address_zip: 'a', foreign_monitored_address_county: 'a', primary_telephone: '+11111111111',
                               primary_telephone_type: 'a', secondary_telephone: '+11111111111', secondary_telephone_type: 'a', email: 'foo@bar.com',
                               preferred_contact_method: 'Telephone call', preferred_contact_time: 'Morning', port_of_origin: 'a', source_of_report: 'a',
                               flight_or_vessel_number: 'a', flight_or_vessel_carrier: 'a', port_of_entry_into_usa: 'a',
                               travel_related_notes: 'a', additional_planned_travel_type: 'a', additional_planned_travel_destination: 'a',
                               additional_planned_travel_destination_state: 'a', additional_planned_travel_destination_country: 'a',
                               additional_planned_travel_port_of_departure: 'a', date_of_departure: 1.month.ago,
                               date_of_arrival: 1.month.ago, additional_planned_travel_start_date: 30.days.from_now,
                               additional_planned_travel_end_date: 30.days.from_now, additional_planned_travel_related_notes: 'a',
                               last_date_of_exposure: 1.month.ago, potential_exposure_location: 'a', potential_exposure_country: 'a',
                               contact_of_known_case: false, contact_of_known_case_id: '1', member_of_a_common_exposure_cohort: false,
                               member_of_a_common_exposure_cohort_type: 'a', travel_to_affected_country_or_area: false,
                               laboratory_personnel: false, laboratory_personnel_facility_name: 'a', healthcare_personnel: false,
                               healthcare_personnel_facility_name: 'a', crew_on_passenger_or_cargo_flight: false,
                               was_in_health_care_facility_with_known_cases: false, was_in_health_care_facility_with_known_cases_facility_name: 'a',
                               exposure_notes: 'a', isolation: false, closed_at: 1.month.ago, source_of_report_specify: 'a',
                               pause_notifications: false, symptom_onset: 1.month.ago, case_status: 'a', assigned_user: 1,
                               latest_assessment_at: 1.month.ago, latest_fever_or_fever_reducer_at: 1.month.ago,
                               latest_positive_lab_at: 1.month.ago, negative_lab_count: 0, latest_transfer_at: 1.month.ago,
                               latest_transfer_from: 1, gender_identity: 'a', sexual_orientation: 'a', user_defined_symptom_onset: false)
    patient.update(close_contacts: [create(:close_contact, patient: patient)])
    patient.update(laboratories: [create(:laboratory, patient: patient)])
    patient.update(histories: [create(:history, patient: patient, history_type: 'Comment')])
    patient.update(contact_attempts: [create(:contact_attempt, patient: patient)])
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'].minutes + 14.days).ago)

    PurgeJob.perform_now
    patient.reload
    patient_attributes = patient.attributes
    assert_not(patient_attributes.delete('monitoring'))
    assert_not(patient_attributes.delete('continuous_exposure'))
    patient.attributes.each do |attribute|
      if PurgeJob.send(:attributes_to_keep).include?(attribute[0])
        assert(!attribute[1].nil?)
      else
        assert_nil(attribute[1])
      end
    end
    assert_empty(patient.laboratories)
    assert_empty(patient.close_contacts)
    assert_empty(patient.histories)
    assert_empty(patient.contact_attempts)
  end
end
