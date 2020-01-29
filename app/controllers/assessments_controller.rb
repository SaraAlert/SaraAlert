class AssessmentsController < ApplicationController

  def index
  end

  def new
    @assessment = Assessment.new
  end

  def create
    @assessment = Assessment.new(params[:assessment].permit(:temperature, :felt_feverish, :cough, :sore_throat, :difficulty_breathing, :muscle_aches, :headache, :abdominal_discomfort, :vomiting, :diarrhea))
    if (@assessment.temperature && @assessment.temperature.to_i > 100 ||
        @assessment.attributes.slice('felt_feverish', 'cough', 'sore_throat', 'difficulty_breathing', 'muscle_aches', 'headache', 'abdominal_discomfort', 'vomiting', 'diarrhea').values.any?)
      @assessment.status = 'symptomatic'
    else
      @assessment.status = 'asymptomatic'
    end
    @assessment.patient_id = params[:patient_id]
    # Attempt to save and continue; else if failed redirect to index
    if @assessment.save!
      # TODO Figure out what to do if save is not successful
      redirect_to patient_assessments_url
    end
  end

end
