# frozen_string_literal: true

# PatientsController: handles all subject actions
class PatientsController < ApplicationController
  before_action :authenticate_user!

  # Enroller view to see enrolled subjects and button to enroll new subjects
  def index
    redirect_to(root_url) && return unless current_user.can_create_patient?
  end

  # The single subject view
  def show
    redirect_to(root_url) && return unless current_user.can_view_patient?

    @patient = current_user.get_patient(params.permit(:id)[:id])

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?

    @group_members = @patient.dependents.where.not(id: @patient.id)

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?
  end

  # Returns a new (unsaved) subject, for creating a new subject
  def new
    redirect_to(root_url) && return unless current_user.can_create_patient?
    @patient = Patient.new
  end

  # Similar to 'new', except used for creating a new group member
  def new_group_member
    redirect_to(root_url) && return unless current_user.can_create_patient?

    # Find the parent subject
    parent = current_user.get_patient(params.permit(:id)[:id])

    # If we failed to find the parent given the id, redirect to index
    redirect_to(root_url) && return if parent.nil?

    @patient = Patient.new(parent.attributes.slice(*group_member_subset.map(&:to_s)))

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?

    @parent_id = parent.id
  end

  # Editing a patient
  def edit
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    @patient = current_user.get_patient(params.permit(:id)[:id])

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?
  end

  # This follows 'new', this will receive the subject details and save a new subject
  # to the database.
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient? || current_user.can_import?

    # Check for potential duplicate
    unless params[:bypass_duplicate]
      duplicate = current_user.viewable_patients.matches(params[:patient].permit(*allowed_params)[:first_name],
                                                         params[:patient].permit(*allowed_params)[:last_name],
                                                         params[:patient].permit(*allowed_params)[:sex],
                                                         params[:patient].permit(*allowed_params)[:date_of_birth]).count.positive?
      render(json: { duplicate: true }) && return if duplicate
    end

    # Add patient details that were collected from the form
    patient = Patient.new(params[:patient].permit(*allowed_params))

    # Set the responder for this patient
    patient.responder = if params.permit(:responder_id)[:responder_id]
                          current_user.get_patient(params.permit(:responder_id)[:responder_id])
                        else
                          patient
                        end

    # Set the creator as the current user
    patient.creator = current_user

    # Set the subject jurisdiction to the creator's jurisdiction
    patient.jurisdiction = current_user.jurisdiction

    # Create a secure random token to act as the monitoree's password when they submit assessments; this gets
    # included in the URL sent to the monitoree to allow them to report without having to type in a password
    patient.submission_token = SecureRandom.hex(20) # 160 bits

    # Attempt to save and continue; else if failed redirect to index
    if patient.save
      send_enrollment_notification(patient)

      # Create a history for the enrollment
      history = History.new
      history.created_by = current_user.email
      history.comment = 'User enrolled monitoree.'
      history.patient = patient
      history.history_type = 'Enrollment'
      history.save

      render(json: patient) && return
    else
      render(file: File.join(Rails.root, 'public/422.html'), status: 422, layout: false)
    end
  end

  def send_enrollment_notification(patient)
    # TODO: An error should be raised to the user if no email/text was delivered (e.g. if redis is not running)
    # TODO: Also consider recording on the patient whether an email/text was sent and run a regular job to retry sending unsent
    # TODO: Switch on preferred primary contact
    if patient.email.present? && patient.preferred_contact_method == 'E-mailed Web Link'
      # deliver_later forces the use of ActiveJob
      # sidekiq and redis should be running for this to work
      # If these are not running, all jobs will be completed when services start
      PatientMailer.enrollment_email(patient).deliver_later if ADMIN_OPTIONS['enable_email'] && !Rails.env.test?
    elsif patient.primary_telephone.present? && patient.preferred_contact_method == 'SMS Texted Weblink'
      # deliver_later forces the use of ActiveJob
      # sidekiq and redis should be running for this to work
      # If these are not running, all jobs will be completed when services start
      PatientMailer.enrollment_sms_weblink(patient).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
    elsif patient.primary_telephone.present? && patient.preferred_contact_method == 'SMS Text-message'
      # deliver_later forces the use of ActiveJob
      # sidekiq and redis should be running for this to work
      # If these are not running, all jobs will be completed when services start
      PatientMailer.enrollment_sms_text_based(patient).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
    end
  end

  # General updates to an existing subject.
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    content = params.require(:patient).permit(:patient, :id, *allowed_params)
    patient = current_user.get_patient(content[:id])

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if patient.nil?

    # Attempt to update, else return to index if failed
    redirect_to(root_url) && return unless patient.update!(content)

    render json: patient
  end

  # Updates to workflow/tracking status for a subject
  def update_status
    redirect_to(root_url) && return unless current_user.can_edit_patient?
    patient = current_user.get_patient(params.permit(:id)[:id])
    patient.update!(params.require(:patient).permit(:monitoring, :monitoring_reason, :monitoring_plan, :exposure_risk_assessment, :public_health_action))
    if !params.permit(:jurisdiction)[:jurisdiction].nil? && params.permit(:jurisdiction)[:jurisdiction] != patient.jurisdiction_id
      # Jurisdiction has changed
      jur = Jurisdiction.find_by_id(params.permit(:jurisdiction)[:jurisdiction])
      unless jur.nil?
        transfer = Transfer.new(patient: patient, from_jurisdiction: patient.jurisdiction, to_jurisdiction: jur, who: current_user)
        transfer.save!
        patient.jurisdiction_id = jur.id
      end
    end
    patient.save!

    # Do we need to propogate to household?
    if params.permit(:apply_to_group)[:apply_to_group]
      patient.dependents.where.not(id: patient.id).each do |member|
        member.update!(params.require(:patient).permit(:monitoring, :monitoring_reason, :monitoring_plan, :exposure_risk_assessment, :public_health_action))
        if !params.permit(:jurisdiction)[:jurisdiction].nil? && params.permit(:jurisdiction)[:jurisdiction] != member.jurisdiction_id
          # Jurisdiction has changed
          jur = Jurisdiction.find_by_id(params.permit(:jurisdiction)[:jurisdiction])
          unless jur.nil?
            transfer = Transfer.new(patient: member, from_jurisdiction: member.jurisdiction, to_jurisdiction: jur, who: current_user)
            transfer.save!
            member.jurisdiction_id = jur.id
          end
        end
        member.save!
        history = History.new
        history.created_by = current_user.email
        comment = 'User changed '
        comment += params.permit(:message)[:message] unless params.permit(:message)[:message].blank?
        comment += ' Reason: ' + params.permit(:reasoning)[:reasoning] unless params.permit(:reasoning)[:reasoning].blank?
        history.comment = comment
        history.patient = member
        history.history_type = 'Monitoring Change'
        history.save
      end
    end

    history = History.new
    history.created_by = current_user.email
    comment = 'User changed '
    comment += params.permit(:message)[:message] unless params.permit(:message)[:message].blank?
    comment += ' Reason: ' + params.permit(:reasoning)[:reasoning] unless params.permit(:reasoning)[:reasoning].blank?
    history.comment = comment
    history.patient = patient
    history.history_type = 'Monitoring Change'
    history.save
  end

  def clear_assessments
    redirect_to(root_url) && return unless current_user.can_edit_patient?
    patient = current_user.get_patient(params.permit(:id)[:id])
    patient.assessments.each do |assessment|
      assessment.symptomatic = false
      assessment.save!
    end
    history = History.new
    history.created_by = current_user.email
    comment = 'User reviewed all reports.'
    comment += ' Reason: ' + params.permit(:reasoning)[:reasoning] unless params.permit(:reasoning)[:reasoning].blank?
    history.comment = comment
    history.patient = patient
    history.history_type = 'Reports Reviewed'
    history.save
  end

  def send_reminder
    # Send a new report reminder to the monitoree
    redirect_to(root_url) && return unless current_user.can_remind_patient?
    patient = current_user.get_patient(params.permit(:id)[:id])
    redirect_to(root_url) && return if patient.nil?
    patient.send_assessment(true)

    history = History.new
    history.created_by = current_user.email
    history.comment = 'User sent a report reminder to the monitoree.'
    history.patient = patient
    history.history_type = 'Report Reminder'
    history.save
  end

  # Parameters allowed for saving to database
  def allowed_params
    %i[
      user_defined_id_statelocal
      user_defined_id_cdc
      user_defined_id_nndss
      first_name
      middle_name
      last_name
      date_of_birth
      age
      sex
      white
      black_or_african_american
      american_indian_or_alaska_native
      asian
      native_hawaiian_or_other_pacific_islander
      ethnicity
      primary_language
      secondary_language
      interpretation_required
      nationality
      address_line_1
      foreign_address_line_1
      address_city
      address_state
      address_line_2
      address_zip
      address_county
      monitored_address_line_1
      monitored_address_city
      monitored_address_state
      monitored_address_line_2
      monitored_address_zip
      monitored_address_county
      foreign_address_city
      foreign_address_country
      foreign_address_line_2
      foreign_address_zip
      foreign_address_line_3
      foreign_address_state
      foreign_monitored_address_line_1
      foreign_monitored_address_city
      foreign_monitored_address_state
      foreign_monitored_address_line_2
      foreign_monitored_address_zip
      foreign_monitored_address_county
      primary_telephone
      primary_telephone_type
      secondary_telephone
      secondary_telephone_type
      email
      preferred_contact_method
      preferred_contact_time
      port_of_origin
      source_of_report
      flight_or_vessel_number
      flight_or_vessel_carrier
      port_of_entry_into_usa
      travel_related_notes
      additional_planned_travel_type
      additional_planned_travel_destination
      additional_planned_travel_destination_state
      additional_planned_travel_destination_country
      additional_planned_travel_port_of_departure
      date_of_departure
      date_of_arrival
      additional_planned_travel_start_date
      additional_planned_travel_end_date
      additional_planned_travel_related_notes
      last_date_of_exposure
      potential_exposure_location
      potential_exposure_country
      contact_of_known_case
      contact_of_known_case_id
      travel_to_affected_country_or_area
      was_in_health_care_facility_with_known_cases
      was_in_health_care_facility_with_known_cases_facility_name
      laboratory_personnel
      laboratory_personnel_facility_name
      healthcare_personnel
      healthcare_personnel_facility_name
      exposure_notes
      crew_on_passenger_or_cargo_flight
      monitoring_plan
      exposure_risk_assessment
      member_of_a_common_exposure_cohort
      member_of_a_common_exposure_cohort_type
    ]
  end

  # Fields that should be copied over from parent to group member for easier form completion
  def group_member_subset
    %i[
      address_line_1
      foreign_address_line_1
      address_city
      address_state
      address_line_2
      address_zip
      address_county
      monitored_address_line_1
      monitored_address_city
      monitored_address_state
      monitored_address_line_2
      monitored_address_zip
      monitored_address_county
      foreign_address_city
      foreign_address_country
      foreign_address_line_2
      foreign_address_zip
      foreign_address_line_3
      foreign_address_state
      foreign_monitored_address_line_1
      foreign_monitored_address_city
      foreign_monitored_address_state
      foreign_monitored_address_line_2
      foreign_monitored_address_zip
      foreign_monitored_address_county
      primary_telephone
      primary_telephone_type
      secondary_telephone
      secondary_telephone_type
      email
      preferred_contact_method
      preferred_contact_time
      port_of_origin
      source_of_report
      flight_or_vessel_number
      flight_or_vessel_carrier
      port_of_entry_into_usa
      travel_related_notes
      additional_planned_travel_type
      additional_planned_travel_destination
      additional_planned_travel_destination_state
      additional_planned_travel_destination_country
      additional_planned_travel_port_of_departure
      date_of_departure
      date_of_arrival
      additional_planned_travel_start_date
      additional_planned_travel_end_date
      additional_planned_travel_related_notes
      last_date_of_exposure
      potential_exposure_location
      potential_exposure_country
      contact_of_known_case
      contact_of_known_case_id
      travel_to_affected_country_or_area
      was_in_health_care_facility_with_known_cases
      was_in_health_care_facility_with_known_cases_facility_name
      laboratory_personnel
      laboratory_personnel_facility_name
      healthcare_personnel
      healthcare_personnel_facility_name
      exposure_notes
      crew_on_passenger_or_cargo_flight
      member_of_a_common_exposure_cohort
      member_of_a_common_exposure_cohort_type
    ]
  end
end
