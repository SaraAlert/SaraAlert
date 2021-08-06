# frozen_string_literal: true

require_relative '../../config/environment'
require_relative '../benchmark'
require_relative '../../app/helpers/assessment_query_helper'

def divider
  puts "\n\n#{'-' * 80}\n\n"
end

micro_results = []

# Time Threshold: 15 seconds (This is just for a baseline)
micro_results << benchmark(
  name: 'PatientCountBaseline',
  time_threshold: 15,
  mode: :real,
  no_exit: true
) { Patient.count }

divider

# Time Threshold: 7 seconds
# Setup: Changes time to around 1pm Eastern
# Teardown: Returns to current time
micro_results << benchmark(
  name: 'PatientReminderEligible',
  time_threshold: 7,
  no_exit: true,
  mode: :real,
  setup: proc { Timecop.travel(Time.now.utc.change(hour: 18)) },
  teardown: proc { Timecop.return }
) { Patient.reminder_eligible.count }

divider

# Time Threshold: 0.2 seconds
# Setup: Create patient and add many assessments
patient = Patient.create!(creator: User.first, jurisdiction: Jurisdiction.first, responder: Patient.first)
micro_results << benchmark(
  name: 'PatientAssessmentQuerying',
  time_threshold: 0.2,
  no_exit: true,
  setup: proc {
    assessments = []
    100.times { assessments << Assessment.new(patient_id: patient.id, symptomatic: false) }
    Assessment.import! assessments

    reported_condition = patient.jurisdiction.hierarchical_condition_unpopulated_symptoms
    hash = reported_condition.threshold_condition_hash
    conditions = []
    patient.assessments.each { |assessment| conditions << ReportedCondition.new(assessment_id: assessment.id, threshold_condition_hash: hash) }
    ReportedCondition.import! conditions

    symptoms = []
    patient.assessments.joins(:reported_condition).pluck('conditions.id').each do |condition_id|
      reported_symptoms = reported_condition.symptoms.map do |symptom|
        symptom[:condition_id] = condition_id
        symptom
      end
      symptoms.concat(reported_symptoms)
    end
    Symptom.import! symptoms
  }
) do
  assessments = AssessmentQueryHelper.search(patient.assessments, '')
  assessments = AssessmentQueryHelper.sort(assessments, 'id', 'asc')
  assessments = AssessmentQueryHelper.paginate(assessments, 100, 0)
  AssessmentQueryHelper.format_for_frontend(assessments)
end

divider

# This micro test actually modifies the database,
# so it is best to leave it as the last benchmark.
# Time Threshold: 7 seconds
# Setup: Changes many patients to be close_eligible
micro_results << benchmark(
  name: 'PatientCloseEligible',
  time_threshold: 7,
  no_exit: true,
  mode: :real,
  setup: proc {
    puts 'updating patients'
    max_num_to_close = 20_000
    # Due to the `no_recent_activity` criteria of the close_eligible scope
    # it is necessary to change the updated_at of all patients so that
    # we do not go over `max_num_to_close`
    # Skip model validations as they are not needed in the benchmark.
    # rubocop:disable Rails/SkipsModelValidations
    Patient.update_all(updated_at: DateTime.now)
    Patient.limit(max_num_to_close).update_all(
      isolation: false,
      continuous_exposure: false,
      latest_assessment_at: DateTime.now,
      symptom_onset: nil,
      public_health_action: 'None',
      purged: false,
      monitoring: true,
      created_at: 100.days.ago,
      last_date_of_exposure: 100.days.ago,
      email: 'testpatient@example.com',
      primary_telephone: '+12223334444'
    )
    # rubocop:enable Rails/SkipsModelValidations
  }
) { Patient.close_eligible.count }

divider

if micro_results.include? false
  puts 'ONE OR MORE MICRO BENCHMARKS FAILED'
  exit(1)
else
  puts 'ALL MICRO BENCHMARKS PASSED'
  exit(0)
end
