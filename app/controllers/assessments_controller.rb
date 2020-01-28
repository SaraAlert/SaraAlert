class AssessmentsController < ApplicationController

    def new
        @assessment = Assessment.new
    end

    def create
        @assessment = Assessment.new(params[:assessment].permit(:showing_symptoms))
        @assessment.patient_id = params[:patient_id]
        # Attempt to save and continue; else if failed redirect to index
        if @assessment.save!
            # TODO Figure out what to do if save is not successful
            redirect_to action: 'index'
        end
    end

end
