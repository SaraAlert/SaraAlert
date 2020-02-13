class AssessmentsController < ApplicationController

  def index
  end

  def new
    # TODO: We need to check the assessment token for all actions in this controller
    @assessment = Assessment.new
    @patient_submission_token = params[:patient_submission_token]
  end

  def create
    # The patient providing this assessment is identified through the submission_token
    patient = Patient.find_by(submission_token: params.permit(:patient_submission_token)[:patient_submission_token])
    redirect_to root_url unless patient
    @assessment = Assessment.new(params.permit(:temperature, :felt_feverish, :cough, :sore_throat, :difficulty_breathing, :muscle_aches, :headache, :abdominal_discomfort, :vomiting, :diarrhea))
    @assessment.patient = patient

    # Cache the overall thought on whether these symptoms are concerning
    if (@assessment.temperature && @assessment.temperature.to_i > 100 ||
        @assessment.attributes.slice('felt_feverish', 'cough', 'sore_throat', 'difficulty_breathing', 'muscle_aches', 'headache', 'abdominal_discomfort', 'vomiting', 'diarrhea').values.any?)
      @assessment.symptomatic = true
    else
      @assessment.symptomatic = false
    end
    # Attempt to save and continue; else if failed redirect to index
    if @assessment.save!
      # TODO Figure out what to do if save is not successful
      redirect_to patient_assessments_url
    end
  end

end
