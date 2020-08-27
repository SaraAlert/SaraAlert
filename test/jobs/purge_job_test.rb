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
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'] + 1).minute.ago)
    email = PurgeJob.perform_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not ActionMailer::Base.deliveries.empty?
    assert_includes(email_body, patient.id.to_s)
  end

  test 'sends an email with all non purged monitorees' do
    patient = create(:patient, monitoring: false, purged: false)
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'] + 1).minute.ago)

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
    dependent = create(:patient, monitoring: true, responder_id: patient)
    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'] + 1).minute.ago, dependents: patient.dependents << dependent)

    PurgeJob.perform_now
    patient.reload
    # Head of household was not purged; check for attributes that should not have been deleted
    assert(patient.address_line_1)
  end

  test 'cleans up downloads' do
    patient = create(:patient, monitoring: false, purged: false)
    create(:download, created_at: 25.hours.ago)
    PurgeJob.perform_now
    assert(Download.count == 0)
  end

  test 'cleans up assessment receipts' do
    patient = create(:patient, monitoring: false, purged: false)
    create(:assessment_receipt, created_at: 25.hours.ago)
    PurgeJob.perform_now
    assert(AssessmentReceipt.count == 0)
  end

  test 'cleans up symptoms, reported conditions, and assessments of purged patients' do
    patient = create(:patient, monitoring: false, purged: false)

    assessment = create(:assessment, patient: patient)
    reported_condition = create(:reported_condition, assessment: assessment)
    symptom = create(:symptom, condition_id: reported_condition.id)

    patient.update(updated_at: (ADMIN_OPTIONS['purgeable_after'] + 1).minute.ago)
    PurgeJob.perform_now
    assert(Assessment.count == 0)
    assert(ReportedCondition.count == 0)
    assert(Symptom.count == 0)
  end
end
