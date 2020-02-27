class AssessmentsController < ApplicationController
  before_action :check_patient_token, only: [:new, :create, :update]

  def index
  end

  def new
    @assessment = Assessment.new
    @patient_submission_token = params[:patient_submission_token]
  end

  def create
    # The patient providing this assessment is identified through the submission_token
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])

    @assessment = Assessment.new(params.permit(*assessment_params))
    @assessment.patient = patient

    # Cache the overall thought on whether these symptoms are concerning
    if (@assessment.temperature && @assessment.temperature.to_i >= 100.4 ||
        @assessment.attributes.slice(*(symptoms.map { |s| s.to_s })).values.any?)
      @assessment.symptomatic = true
    else
      @assessment.symptomatic = false
    end

    # Determine if a user created this assessment or a monitoree
    if current_user.nil?
      @assessment.who_reported = 'Monitoree'
    else
      @assessment.who_reported = current_user.email
    end

    # Attempt to save and continue; else if failed redirect to index
    if @assessment.save!
      redirect_to patient_assessments_url and return
    end
  end

  def update
    redirect_to root_url unless current_user&.can_edit_patient_assessments?
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
    assessment = Assessment.find_by(id: params.permit(:id)[:id])
    assessment.update!(params.permit(*assessment_params))
    if (assessment.temperature && assessment.temperature.to_i >= 100.4 ||
      assessment.attributes.slice(*(symptoms.map { |s| s.to_s })).values.any?)
      assessment.symptomatic = true
    else
      assessment.symptomatic = false
    end
    # Monitorees can't edit their own assessments, so the last person to touch this assessment was current_user
    assessment.who_reported = current_user.email
    assessment.save!
  end

  def check_patient_token
    if params.nil? || params[:patient_submission_token].nil?
      redirect_to root_url and return
    end
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
    if patient.nil?
      redirect_to root_url and return
    end
  end

  def assessment_params
    [
      :temperature
    ] + symptoms
  end

  def symptoms
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
