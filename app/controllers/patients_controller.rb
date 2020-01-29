class PatientsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to root_url unless current_user.can_view_patient?
  end

  def show
    redirect_to root_url unless current_user.can_view_patient?
    # Retrieve Patient by id, but only check patients that current_user created
    @patient = current_user.created_patients.find_by_id(params.permit(:id)[:id])
    # Or that the current user is monitoring
    # TODO: Once we have jurisdictions we need to specify access control rules in the cancan ability file
    if (current_user.has_role?(:monitor))
      @patient ||= Patient.find_by_id(params.permit(:id)[:id])
    end
    # If we failed to find a patient given the id, redirect to index
    redirect_to action: 'index' if @patient.nil?
  end

  def new
    redirect_to root_url unless current_user.can_create_patient?
    @patient = Patient.new
  end

  def create
    redirect_to root_url unless current_user.can_create_patient?

    # Add patient details that were collected from the form
    patient = Patient.new(params[:patient].permit(:first_name,
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
    patient.responder = patient

    # Set the creator as the current user
    patient.creator = current_user

    # Create a secure random token to act as the subject's password when they submit assessments; this gets
    # included in the URL sent to the subject to allow them to report without having to type in a password
    # TODO: This currently a notional solution, and any final solution will require a security review
    patient.submission_token = SecureRandom.hex(20) # 160 bits

    # Attempt to save and continue; else if failed redirect to index
    if patient.save
      # TODO: An error should be raised to the user if no email/text was delivered (e.g. if redis is not running)
      # TODO: Also consider recording on the patient whether an email/text was sent and run a regular job to retry sending unsent
      # TODO: Switch on preferred primary contact
      if patient.email.present?
        # deliver_later forces the use of ActiveJob
        # sidekiq and redis should be running for this to work
        # If these are not running, all jobs will be completed when services start
        PatientMailer.enrollment_email(patient).deliver_later
      end
      if patient.primary_phone.present?
        # deliver_later forces the use of ActiveJob
        # sidekiq and redis should be running for this to work
        # If these are not running, all jobs will be completed when services start
        PatientMailer.enrollment_sms(patient).deliver_later
      end
      redirect_to patient
    else
      redirect_to action: 'index'
    end
  end

end
