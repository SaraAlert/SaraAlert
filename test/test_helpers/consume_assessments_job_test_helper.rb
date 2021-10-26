# frozen_string_literal: true

module ConsumeAssessmentsJobTestHelper
  class AssessmentGenerator
    @@response_statuses = %w[no_answer_voice no_answer_sms error_voice error_sms]

    def initialize(patient)
      @patient = patient
    end

    def self.response_statuses
      @@response_statuses
    end

    def reported_symptom_assessment(symptomatic: nil)
      message = {
        response_status: nil,
        error_code: nil,
        threshold_condition_hash: @patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: symptomatic,
        patient_submission_token: @patient.submission_token
      }

      reported_symptoms_array = {
        reported_symptoms_array: [{
          name: 'Cough',
          value: false,
          type: 'BoolSymptom',
          label: 'Cough',
          notes: 'Have you coughed today?',
          required: false
        }]
      }
      # If symptomatic is nil then we will include a reported_symptoms_array
      # the reported_symptoms_array exists when assessments are completed in the web-form
      message.merge!(reported_symptoms_array) if symptomatic.nil?
      message.to_json
    end

    def generic_assessment(symptomatic:)
      {
        response_status: nil,
        error_code: nil,
        threshold_condition_hash: @patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: symptomatic,
        patient_submission_token: @patient.submission_token
      }.to_json
    end

    def error_sms_assessment(error_code: TwilioSender::TWILIO_ERROR_CODES[:unknown_error][:code], patient: @patient)
      {
        response_status: 'error_sms',
        error_code: error_code,
        threshold_condition_hash: patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: nil,
        patient_submission_token: patient.submission_token
      }.to_json
    end

    def error_voice_assessment(error_code: TwilioSender::TWILIO_ERROR_CODES[:unknown_error][:code], patient: @patient)
      {
        response_status: 'error_voice',
        error_code: error_code,
        threshold_condition_hash: patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: nil,
        patient_submission_token: patient.submission_token
      }.to_json
    end

    def missing_threshold_condition
      {
        response_status: nil,
        error_code: nil,
        threshold_condition_hash: nil,
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
        error_code: nil,
        threshold_condition_hash: @patient.jurisdiction.hierarchical_symptomatic_condition.threshold_condition_hash,
        reported_symptoms_array: nil,
        experiencing_symptoms: nil,
        patient_submission_token: @patient.submission_token
      }.to_json
    end
  end
end
