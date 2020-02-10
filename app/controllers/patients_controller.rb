class PatientsController < ApplicationController
  before_action :authenticate_user!
  before_action :get_stats, only: [:index]

  def index
    # TODO: Should this be can_create_patient?
    redirect_to root_url unless current_user.can_view_patient?
  end

  def show
    redirect_to root_url unless current_user.can_view_patient?
    # Retrieve Patient by id, but only check patients that current_user created
    @patient = current_user.created_patients.find_by_id(params.permit(:id)[:id])
    # Or that the current user is monitoring
    # TODO: We should specify access control rules in the cancan ability file
    if (current_user.has_role?(:monitor))
      @patient ||= current_user.viewable_patients&.find_by_id(params.permit(:id)[:id])
    end
    # If we failed to find a patient given the id, redirect to index
    redirect_to action: 'index' if @patient.nil?
  end

  def new
    redirect_to root_url unless current_user.can_create_patient?
    @patient = Patient.new
  end

  def create
    # TODO: This is accessed via React, so redirects are probably not sensible behavior
    redirect_to root_url unless current_user.can_create_patient?

    # Add patient details that were collected from the form
    patient = Patient.new(params[:patient].permit(:first_name,
                                                  :middle_name,
                                                  :last_name,
                                                  :date_of_birth,
                                                  :age,
                                                  :sex,
                                                  :white,
                                                  :black_or_african_american,
                                                  :american_indian_or_alaska_native,
                                                  :asian,
                                                  :native_hawaiian_or_other_pacific_islander,
                                                  :ethnicity,
                                                  :primary_language,
                                                  :interpretation_required,
                                                  :address_line_1,
                                                  :foreign_address_line_1,
                                                  :address_city,
                                                  :address_state,
                                                  :address_line_2,
                                                  :address_zip,
                                                  :address_county,
                                                  :monitored_address_line_1,
                                                  :monitored_address_city,
                                                  :monitored_address_state,
                                                  :monitored_address_line_2,
                                                  :monitored_address_zip,
                                                  :monitored_address_county,
                                                  :foreign_address_city,
                                                  :foreign_address_country,
                                                  :foreign_address_line_2,
                                                  :foreign_address_zip,
                                                  :foreign_address_line_3,
                                                  :foreign_address_state,
                                                  :foreign_monitored_address_line_1,
                                                  :foreign_monitored_address_city,
                                                  :foreign_monitored_address_state,
                                                  :foreign_monitored_address_line_2,
                                                  :foreign_monitored_address_zip,
                                                  :foreign_monitored_address_county,
                                                  :primary_telephone,
                                                  :primary_telephone_type,
                                                  :secondary_telephone,
                                                  :secondary_telephone_type,
                                                  :email,
                                                  :preferred_contact_method,
                                                  :port_of_origin,
                                                  :source_of_report,
                                                  :flight_or_vessel_number,
                                                  :flight_or_vessel_carrier,
                                                  :port_of_entry_into_usa,
                                                  :travel_related_notes,
                                                  :additional_planned_travel_type,
                                                  :additional_planned_travel_destination,
                                                  :additional_planned_travel_destination_state,
                                                  :additional_planned_travel_port_of_departure,
                                                  :date_of_departure,
                                                  :date_of_arrival,
                                                  :additional_planned_travel_start_date,
                                                  :additional_planned_travel_end_date,
                                                  :additional_planned_travel_related_notes,
                                                  :last_date_of_potential_exposure,
                                                  :potential_exposure_location,
                                                  :potential_exposure_country,
                                                  :contact_of_known_case,
                                                  :contact_of_known_case_id,
                                                  :healthcare_worker,
                                                  :worked_in_health_care_facility))

    # Set the responder for this patient as that patient
    patient.responder = patient

    # Set the creator as the current user
    patient.creator = current_user

    # TODO: We need to correctly assign this patient to a jurisdiction; for now just assume the jurisidiction of the user
    patient.jurisdiction = current_user.jurisdiction

    # Create a secure random token to act as the subject's password when they submit assessments; this gets
    # included in the URL sent to the subject to allow them to report without having to type in a password
    # TODO: This is currently a notional solution, and any final solution will require a security review
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
      if patient.primary_telephone.present?
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

  def get_stats
    @stats = {
      system_subjects: Patient.count,
      system_subjects_last_24: Patient.where('created_at >= ?', Time.now - 1.day).count,
      system_assessmets: Assessment.count,
      system_assessmets_last_24: Assessment.where('created_at >= ?', Time.now - 1.day).count,
      user_subjects: Patient.where(creator_id: current_user.id).count,
      user_subjects_last_24: Patient.where(creator_id: current_user.id).where('created_at >= ?', Time.now - 1.day).count,
      user_assessments: Patient.where(creator_id: current_user.id).joins(:assessments).count,
      user_assessments_last_24: Patient.where(creator_id: current_user.id).joins(:assessments).where('assessments.created_at >= ?', Time.now - 1.day).count
    }
  end

end
