# frozen_string_literal: true

module ConsumeAssessmentsWorkerTestHelper
  class AssessmentGenerator
    attr_reader :patient

    @@response_statuses = %w[no_answer_voice no_answer_sms error_voice error_sms]

    def initialize(patient)
      @patient = patient
    end

    def self.response_statuses
      @@response_statuses
    end

    def invalid_submission_token
      { response_status: nil,
        threshold_condition_hash: @patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: false,
        patient_submission_token: 'invalid token'
      }.to_json
    end

    def reported_symptom_assessment(symptomatic: nil)
      {
        response_status: nil,
        threshold_condition_hash: @patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: [
          {
            name: 'Cough',
            value: false,
            type: 'BoolSymptom',
            label: 'Cough',
            notes: 'Have you coughed today?'
          }
        ],
        experiencing_symptoms: symptomatic,
        patient_submission_token: @patient.submission_token
      }.to_json
    end

    def generic_assessment(symptomatic:)
      {
        response_status: nil,
        threshold_condition_hash: @patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: symptomatic,
        patient_submission_token: @patient.submission_token
      }.to_json
    end

    def missing_threshold_condition
      {
        response_status: nil,
        threshold_condition_hash: 'invalid thresholdcondition hash',
        reported_symptoms_array: nil,
        experiencing_symptoms: false,
        patient_submission_token: @patient.submission_token
      }.to_json
    end

    def no_answer_assessment(type)
      unless @@response_statuses.include?(type)
        raise "Type is not included in the list of acceptable Twilio responses for response status. Choose one of #{@@response_statuses}"
      end

      {
        response_status: type,
        threshold_condition_hash: @patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: nil,
        patient_submission_token: @patient.submission_token
      }.to_json
    end
  end
end
