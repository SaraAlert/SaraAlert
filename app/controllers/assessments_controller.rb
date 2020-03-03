# frozen_string_literal: true

# AssessmentsController: for assessment actions
class AssessmentsController < ApplicationController
  before_action :check_patient_token, only: %i[new create update]

  def index; end

  def new
    @assessment = Assessment.new
    @patient_submission_token = params[:patient_submission_token]
    reporting_condition = Patient.find_by(submission_token: params[:patient_submission_token]).jurisdiction.hierarchical_condition_unpopulated_symptoms
    @symptoms = reporting_condition.symptoms
    @threshold_hash = reporting_condition.threshold_condition_hash
  end

  def create
    # The patient providing this assessment is identified through the submission_token
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])

    redirect_to root_url unless patient
    threshold_condition_hash = params.permit(:threshold_hash)[:threshold_hash]
    threshold_condition = ThresholdCondition.where(threshold_condition_hash: threshold_condition_hash).first

    redirect_to root_url unless threshold_condition
  
    reported_symptoms_array = params.permit({:symptoms => [:name, :bool_value, :float_value, :int_value, :field_type, :label]}).to_h['symptoms']

    typed_reported_symptoms = []
    reported_symptoms_array.each { |symp|
      if symp['field_type'] == "FloatSymptom"
        symptom = FloatSymptom.create(symp.except(:field_type))
      elsif symp['field_type'] == "BoolSymptom"
        symptom = BoolSymptom.create(symp.except(:field_type))
      elsif symp['field_type'] == "IntegerSymptom"
        symptom = IntegerSymptom.create(symp.except(:field_type))
      end
      typed_reported_symptoms.push(symptom)
    }

    reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: threshold_condition_hash )


    @assessment = Assessment.new(reported_condition: reported_condition, symptomatic_condition: threshold_condition )
    @assessment.symptomatic = @assessment.is_symptomatic
    @assessment.patient = patient
  

    # Determine if a user created this assessment or a monitoree
    if current_user.nil?
      @assessment.who_reported = 'Monitoree'
    else
      @assessment.who_reported = current_user.email
      history = History.new
      history.created_by = current_user.email
      comment = 'User created a new subject report.'
      history.comment = comment
      history.patient = patient
      history.history_type = 'Report Created'
      history.save!
    end
    # Attempt to save and continue; else if failed redirect to index
    redirect_to(patient_assessments_url) && return if @assessment.save!
  end

  def update
    redirect_to root_url unless current_user&.can_edit_patient_assessments?
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
    assessment = Assessment.find_by(id: params.permit(:id)[:id])
    assessment.update!(params.permit(*assessment_params))
    if (assessment.temperature && assessment.temperature.to_i >= 100.4 ||
      assessment.attributes.slice(*(symps.map { |s| s.to_s })).values.any?)
      assessment.symptomatic = true
    else
      assessment.symptomatic = false
    end
    # Monitorees can't edit their own assessments, so the last person to touch this assessment was current_user
    assessment.who_reported = current_user.email

    # Attempt to save and continue; else if failed redirect to index
    return unless assessment.save!

    history = History.new
    history.created_by = current_user.email
    comment = 'User updated an existing subject report.'
    history.comment = comment
    history.patient = patient
    history.history_type = 'Report Updated'
    history.save!
    redirect_to(patient_assessments_url) && return
  end

  def check_patient_token
    redirect_to(root_url) && return if params.nil? || params[:patient_submission_token].nil?
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
    redirect_to(root_url) && return if patient.nil?
  end

  def assessment_params
    [
      :temperature
    ] + symps
  end

  def symps
    [
      :felt_feverish,
      :cough,
      :sore_throat,
      :difficulty_breathing,
      :muscle_aches,
      :headache,
      :abdominal_discomfort,
      :vomiting,
      :diarrhea
    ]
  end
end
