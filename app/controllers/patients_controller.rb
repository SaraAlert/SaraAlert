class PatientsController < ApplicationController
    before_action :authenticate_user!

    def index
        return unless current_user.can_view_patient?
    end

    def show
        return unless current_user.can_view_patient?
        # Retrieve Patient by id, but only check patients that current_user created
        @patient = current_user.created_patients.find_by_id(params.permit(:id)[:id])
        # If we failed to find a patient given the id, redirect to index
        redirect_to action: 'index' if @patient.nil?
    end

    def new
        return unless current_user.can_create_patient?
        @patient = Patient.new
    end

    def create
        return unless current_user.can_create_patient?

        # Add patient details that were collected from the form
        @patient = Patient.new(params[:patient].permit(:first_name,
                                                       :middle_name,
                                                       :last_name,
                                                       :suffix,
                                                       :sex,
                                                       :dob,
                                                       :age,
                                                       :race,
                                                       :ethnicity,
                                                       :language,
                                                       :residence_line_1,
                                                       :residence_line_2,
                                                       :residence_city,
                                                       :residence_county,
                                                       :residence_state,
                                                       :residence_country,
                                                       :email,
                                                       :primary_phone,
                                                       :secondary_phone))


        # Set the responder for this patient as that patient
        @patient.responder = @patient

        # Set the creator as the current user
        @patient.creator = current_user

        # Attempt to save and continue; else if failed redirect to index
        if @patient.save
            redirect_to @patient
        else
            redirect_to action: 'index'
        end
    end

end
