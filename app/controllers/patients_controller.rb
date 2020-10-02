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

    @jurisdiction_path = @patient.jurisdiction_path

    @possible_jurisdiction_paths = if current_user.can_transfer_patients?
                                     # Allow all jurisdictions as valid transfer options.
                                     Hash[Jurisdiction.all.where.not(name: 'USA').pluck(:id, :path).map { |id, path| [id, path] }]
                                   else
                                     # Otherwise, only show jurisdictions within hierarchy.
                                     Hash[current_user.jurisdiction.subtree.pluck(:id, :path).map { |id, path| [id, path] }]
                                   end

    # Household members (dependents) for the HOH excluding HOH
    @dependents_exclude_hoh = @patient.dependents_exclude_self.where(purged: false)

    # All household members regardless if current patient is HOH
    household = current_user.get_patient(@patient.responder_id)&.dependents
    @household_members = ([@patient] + (household.nil? ? [] : household)).uniq

    # All household members that are in the exposure workflow with continuous exposure excluding the current patient
    @household_members_with_ce_in_exposure_excludes_patient = household.nil? ? [] : household.where(isolation: false, continuous_exposure: true)

    @translations = Assessment.new.translations

    @history_types = History::HISTORY_TYPES

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?
  end

  # Returns a new (unsaved) subject, for creating a new subject
  def new
    redirect_to(root_url) && return unless current_user.can_create_patient?

    # If this is a close contact that is being fully enrolled, grab that record to auto-populate fields
    @close_contact = CloseContact.where(patient_id: current_user.viewable_patients).where(id: params.permit(:cc)[:cc])&.first if params[:cc].present?

    @patient = Patient.new(jurisdiction_id: current_user.jurisdiction_id,
                           isolation: params.permit(:isolation)[:isolation] == 'true',
                           first_name: @close_contact.nil? ? '' : @close_contact.first_name,
                           last_name: @close_contact.nil? ? '' : @close_contact.last_name,
                           primary_telephone: @close_contact.nil? ? '' : @close_contact.primary_telephone,
                           email: @close_contact.nil? ? '' : @close_contact.email,
                           contact_of_known_case: !@close_contact.nil?,
                           contact_of_known_case_id: @close_contact.nil? ? '' : @close_contact.patient_id,
                           exposure_notes: @close_contact.nil? ? '' : @close_contact.notes)
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

    @dependents_exclude_hoh = @patient.dependents_exclude_self
    @propagated_fields = Hash[group_member_subset.collect { |field| [field, false] }]
  end

  # This follows 'new', this will receive the subject details and save a new subject
  # to the database.
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient? || current_user.can_import?

    # Check for potential duplicate
    unless params[:bypass_duplicate]
      duplicate_data = current_user.viewable_patients.duplicate_data(params[:patient].permit(*allowed_params)[:first_name],
                                                                     params[:patient].permit(*allowed_params)[:last_name],
                                                                     params[:patient].permit(*allowed_params)[:sex],
                                                                     params[:patient].permit(*allowed_params)[:date_of_birth],
                                                                     params[:patient].permit(*allowed_params)[:user_defined_id_statelocal])

      render(json: duplicate_data) && return if duplicate_data[:is_duplicate]
    end

    # Add patient details that were collected from the form
    patient = Patient.new(params[:patient].permit(*allowed_params))

    # Default to copying *required address into monitored address if monitored address is nil
    if patient.monitored_address_line_1.nil? || patient.monitored_address_state.nil? ||
       patient.monitored_address_city.nil? || patient.monitored_address_zip.nil?
      patient.monitored_address_line_1 = patient.address_line_1
      patient.monitored_address_line_2 = patient.address_line_2
      patient.monitored_address_city = patient.address_city
      patient.monitored_address_county = patient.address_county
      patient.monitored_address_state = patient.address_state
      patient.monitored_address_zip = patient.address_zip
    end
    helpers.normalize_state_names(patient)
    # Set the responder for this patient, this will link patients that have duplicate primary contact info
    patient.responder = if params.permit(:responder_id)[:responder_id]
                          current_user.get_patient(params.permit(:responder_id)[:responder_id])
                        elsif ['SMS Texted Weblink', 'Telephone call', 'SMS Text-message'].include? patient[:preferred_contact_method]
                          if current_user.viewable_patients.responder_for_number(patient[:primary_telephone])&.exists?
                            current_user.viewable_patients.responder_for_number(patient[:primary_telephone]).first
                          end
                        elsif patient[:preferred_contact_method] == 'E-mailed Web Link'
                          if current_user.viewable_patients.responder_for_email(patient[:email])&.exists?
                            current_user.viewable_patients.responder_for_email(patient[:email]).first
                          end
                        end

    # Default responder to self if no responder condition met
    patient.responder = patient if patient.responder.nil?

    patient.responder = patient.responder.responder if params.permit(:responder_id)[:responder_id] && (patient.responder.responder_id != patient.responder.id)

    # Set the creator as the current user
    patient.creator = current_user

    # Set the subject jurisdiction to the creator's jurisdiction if jurisdiction is not assigned or not assignable by the current user
    valid_jurisdiction = current_user.jurisdiction.subtree_ids.include?(patient.jurisdiction_id) unless patient.jurisdiction_id.nil?
    patient.jurisdiction = current_user.jurisdiction unless valid_jurisdiction

    # Create a secure random token to act as the monitoree's password when they submit assessments; this gets
    # included in the URL sent to the monitoree to allow them to report without having to type in a password
    patient.submission_token = SecureRandom.hex(20) # 160 bits
    # Attempt to save and continue; else if failed redirect to index
    if patient.save

      # Send enrollment notification only to responders
      patient.send_enrollment_notification if patient.self_reporter_or_proxy?

      # Create a history for the enrollment
      History.enrollment(patient: patient, created_by: current_user.email)

      if params[:cc_id].present?
        close_contact = CloseContact.where(patient_id: current_user.viewable_patients).where(id: params.permit(:cc_id)[:cc_id])&.first
        close_contact.update(enrolled_id: patient.id)
      end

      # Create laboratories for patient if included in import
      unless params.dig(:patient, :laboratories).nil?
        params[:patient][:laboratories].each do |lab|
          laboratory = Laboratory.new
          laboratory.lab_type = lab[:lab_type]
          laboratory.specimen_collection = lab[:specimen_collection]
          laboratory.report = lab[:report]
          laboratory.result = lab[:result]
          laboratory.patient = patient
          laboratory.save
        end
      end

      render(json: patient) && return
    else
      render(json: patient.errors, status: 422) && return
    end
  end

  # General updates to an existing subject.
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    content = params.require(:patient).permit(:patient, :id, *allowed_params)
    patient = current_user.get_patient(content[:id])

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if patient.nil?

    # Propagate desired fields to household except jurisdiction_id
    propagated_fields = params[:propagated_fields]
    unless propagated_fields.empty?
      propagated_content = content.select { |field| propagated_fields.include?(field) && field != 'jurisdiction_id' }
      patient.dependents_exclude_self.update(propagated_content)
    end

    # If the assigned jurisdiction is updated, verify that the jurisdiction exists and that it is assignable by the current user, update history and propagate
    if content[:jurisdiction_id] && content[:jurisdiction_id] != patient.jurisdiction_id
      if current_user.jurisdiction.subtree_ids.include?(content[:jurisdiction_id].to_i)
        old_jurisdiction = patient.jurisdiction[:path]
        new_jurisdiction = Jurisdiction.find(content[:jurisdiction_id])[:path]
        transfer = Transfer.new(patient: patient, from_jurisdiction: patient.jurisdiction, to_jurisdiction_id: content[:jurisdiction_id], who: current_user)
        transfer.save!
        comment = "User changed Jurisdiction from \"#{old_jurisdiction}\" to \"#{new_jurisdiction}\"."
        history = History.monitoring_change(patient: patient, created_by: current_user.email, comment: comment)
        if propagated_fields.include?('jurisdiction_id')
          dependents_exclude_hoh = patient.dependents_exclude_self
          dependents_exclude_hoh.update(jurisdiction_id: content[:jurisdiction_id])
          dependents_exclude_hoh.each do |group_member|
            propagated_history = history.dup
            propagated_history.patient = group_member
            propagated_history.comment = "System changed Jurisdiction from \"#{old_jurisdiction}\" to \"#{new_jurisdiction}\" because User updated Jurisdiction
                                          for another member in this monitoree's household and chose to update this field for all household members."
            propagated_history.save
            propagated_transfer = transfer.dup
            propagated_transfer.patient = group_member
            propagated_transfer.save
          end
        end
      else
        content[:jurisdiction_id] = patient.jurisdiction_id
      end
    end

    # If the assigned user is updated, update history and propagate
    if content[:assigned_user] && content[:assigned_user] != patient.assigned_user
      old_assigned_user = patient.assigned_user || ''
      new_assigned_user = content[:assigned_user] || ''
      comment = "User changed Assigned User from \"#{old_assigned_user}\" to \"#{new_assigned_user}\"."
      history = History.monitoring_change(patient: patient, created_by: current_user.email, comment: comment)
      if propagated_fields.include?('assigned_user')
        dependents_exclude_hoh = patient.dependents_exclude_self
        dependents_exclude_hoh.update(assigned_user: content[:assigned_user])
        dependents_exclude_hoh.each do |group_member|
          propagated_history = history.dup
          propagated_history.patient = group_member
          propagated_history.comment = "System changed Assigned User from \"#{old_assigned_user}\" to \"#{new_assigned_user}\" because User updated Assigned
                                        User for another member in this monitoree's household and chose to update this field for all household members."
          propagated_history.save
        end
      end
    end

    # Reset symptom onset date if moving from isolation to exposure
    reset_symptom_onset(content, patient, :system) if !content[:isolation].nil? && !content[:isolation]

    # Update patient history with detailed edit diff
    patient_before = patient.dup
    Patient.detailed_history_edit(patient_before, patient, current_user.email, allowed_params) if patient.update(content)

    render json: patient
  end

  def update_hoh
    new_hoh_id = params.permit(:new_hoh_id)[:new_hoh_id]
    current_patient_id = params.permit(:id)[:id]
    household_ids = params[:household_ids] || []
    # update_all below does not invoke ActiveRecord callbacks and will not automatically check if this incomming
    # id exists. Patient.exists?(nil) => false
    redirect_to(root_url) && return unless Patient.exists?(new_hoh_id.to_i)

    patients_to_update = household_ids + [current_patient_id]
    current_user_patients = if current_user.role?(Roles::ENROLLER)
                              current_user.enrolled_patients
                            else
                              current_user.viewable_patients
                            end
    # Make sure all household ids are within jurisdiction
    redirect_to(root_url) && return if patients_to_update.any? do |patient_id|
      !current_user_patients.exists?(patient_id)
    end

    # Change all of the patients in the household, including the current patient to have new_hoh_id as the responder
    current_user_patients.where(id: patients_to_update).each do |patient|
      patient.update(responder_id: new_hoh_id)
    end
  end

  def bulk_update_status
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    # Nothing to do in this function if there isn't a list of patient ids.
    patient_ids = params.require(:ids)
    non_dependent_patient_ids = patient_ids

    # If apply to group, find dependents ids and add to id array before user accessor for validation of access
    if ActiveModel::Type::Boolean.new.cast(params.require(:apply_to_household))
      dependent_ids = current_user.patients.where(responder_id: patient_ids).pluck(:id)
      # If apply_to_household was set, and there exists a patient that has dependents in a different
      # jurisdiction - one that the user may not have access to - those patients will get filtered out.
      not_viewable = Patient.where(responder_id: patient_ids).pluck(:id) - dependent_ids

      unless not_viewable.empty?
        responders = Patient.find(not_viewable).map(&:responder)
        responders.uniq
        render json: { error: 'Selected monitoree dependents are in a household that spans jurisidictions which you do not have access to.',
                       patients: responders }, status: 401
      end

      patient_ids = patient_ids.union(dependent_ids)
    end
    patients = current_user.get_patients(patient_ids)

    patients.each do |patient|
      update_fields(patient, params, non_dependent_patient_ids.include?(patient[:id]) ? :patient : :dependent, params[:apply_to_household] ? :group : :none)
    end
  end

  # Updates to workflow/tracking status for a subject
  def update_status
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patient = current_user.get_patient(params.permit(:id)[:id])
    redirect_to(root_url) && return if patient.nil?

    # Update LDE for patient and group members only in the exposure workflow with continuous exposure on
    # NOTE: This is a possible option when changing monitoring status of HoH in isolation.
    if params.permit(:apply_to_household_cm_exp_only)[:apply_to_household_cm_exp_only] && params[:apply_to_household_cm_exp_only_date].present?
      # Only update dependents (not including the HoH) in exposure with continuoous exposure is turned on
      (current_user.get_patient(patient.responder_id)&.dependents_exclude_self&.where(continuous_exposure: true, isolation: false) || []).uniq.each do |member|
        History.monitoring_change(patient: member, created_by: 'Sara Alert System', comment: "User updated Monitoring Status for another member in this
        monitoree's household and chose to update Last Date of Exposure for household members so System changed Last Date of Exposure from
        #{member[:last_date_of_exposure] ? member[:last_date_of_exposure].to_date.strftime('%m/%d/%Y') : 'blank'} to
        #{params[:apply_to_household_cm_exp_only_date].to_date.strftime('%m/%d/%Y')} and turned OFF Continuous Exposure.")

        member.update(last_date_of_exposure: params[:apply_to_household_cm_exp_only_date], continuous_exposure: false)
      end
    end

    # Update patient and all group members
    if params.permit(:apply_to_household)[:apply_to_household]
      ([patient] + (current_user.get_patient(patient.responder_id)&.dependents || [])).uniq.each do |member|
        update_fields(member, params, patient[:id] == member[:id] ? :patient : :dependent, :group)
      end
      # Update patient and all group members in continuous exposure
    elsif params.permit(:apply_to_household_cm_only)[:apply_to_household_cm_only] # update patient and group members only with continuous exposure on
      ([patient] + (current_user.get_patient(patient.responder_id)&.dependents&.where(continuous_exposure: true) || [])).uniq.each do |member|
        update_fields(member, params, patient[:id] == member[:id] ? :patient : :dependent, :group_cm)
      end
    else # Update patient
      update_fields(patient, params, :patient, :none)
    end
  end

  def update_fields(patient, params, household, propagation)
    # Figure out what exactly changed, and limit update to only those fields
    diff_state = params[:diffState]&.map(&:to_sym)
    params_to_update = if diff_state.nil?
                         status_fields
                       else
                         status_fields & diff_state # Set intersection between what the front end is saying changed, and status fields
                       end

    # Update history before fields are changed
    history = {
      created_by: current_user.email,
      patient: patient,
      params: params,
      household: household,
      propagation: propagation,
      reason: params[:reasoning]
    }

    History.monitoring_actions(history, diff_state)

    # If the monitoree record was closed, set continuous exposure to be false and set the closed at time.
    if params_to_update.include?(:monitoring) && params.require(:patient).permit(:monitoring)[:monitoring] != patient.monitoring && patient.monitoring
      if patient[:continuous_exposure]
        History.monitoring_change(patient: patient, created_by: 'Sara Alert System', comment: 'System turned off Continuous Exposure because the record was
        moved to the closed line list.')
      end
      patient.continuous_exposure = false
      patient.closed_at = DateTime.now
    end

    # Do not allow continuous exposure to updated for closed records
    params_to_update.delete(:continuous_exposure) if params_to_update.include?(:continuous_exposure) && !patient.monitoring

    # If moving patient to exposure from isolation
    if params_to_update.include?(:isolation) && !params.require(:patient).permit(:isolation)[:isolation]
      # NOTE: In the case where a patient is being moved back to the exposure workflow, the symptom onset should be overwritten
      #       because if a case is being ruled out (moved back to exposure), that patient no longer has no known symptom onset and
      #       shouldn't immediately be put back on the symptomatic line list unless they have symptomatic reports.
      params_to_update.concat(%i[user_defined_symptom_onset symptom_onset])
      reset_symptom_onset(params[:patient], patient, :system)

      # Set extended isolation to nil.
      params_to_update << :extended_isolation
      params[:patient][:extended_isolation] = nil
      unless patient[:extended_isolation].nil?
        History.monitoring_change(patient: patient, created_by: 'Sara Alert System', comment: 'System cleared Extended Isolation Date because monitoree was
        moved from isolation to exposure workflow.')
      end
    end

    # Reset public health action if case status is change to suspect, unknown, not a case
    if params_to_update.include?(:case_status) && ['Suspect', 'Unknown', 'Not a Case'].include?(params.require(:patient).permit(:case_status)[:case_status]) &&
       patient[:public_health_action] != 'None'
      message = patient[:monitoring] ? "System changed Latest Public Health Action from \"#{patient[:public_health_action]}\" to \"None\" so that the monitoree
                                        will appear on the appropriate line list in the exposure workflow to continue monitoring."
                                     : "System changed Latest Public Health Action from \"#{patient[:public_health_action]}\" to \"None\"."
      History.monitoring_change(patient: patient, created_by: 'Sara Alert System', comment: message)
      params_to_update << :public_health_action
      params[:patient][:public_health_action] = 'None'
    end

    # If the symptom onset was cleared by the user
    if params_to_update.include?(:symptom_onset) && params.require(:patient).permit(:symptom_onset)[:symptom_onset].nil?
      params_to_update.concat(%i[user_defined_symptom_onset symptom_onset])
      reset_symptom_onset(params[:patient], patient, :user)
    end

    # Update the patient with updated values.
    patient.update(params.require(:patient).permit(params_to_update))

    if !params.permit(:jurisdiction)[:jurisdiction].nil? && params.permit(:jurisdiction)[:jurisdiction] != patient.jurisdiction_id
      # Jurisdiction has changed
      jur = Jurisdiction.find_by_id(params.permit(:jurisdiction)[:jurisdiction])
      unless jur.nil?
        transfer = Transfer.new(patient: patient, from_jurisdiction: patient.jurisdiction, to_jurisdiction: jur, who: current_user)
        transfer.save!
        patient.jurisdiction_id = jur.id
      end
    end
    patient.save
  end

  def reset_symptom_onset(content, patient, initiator)
    # Set user-defined symptom onset to be false and set the symptom onset date based on latest symptomatic report
    content[:user_defined_symptom_onset] = false
    content[:symptom_onset] = patient.assessments.where(symptomatic: true).minimum(:created_at)&.to_date

    # Log system onset change in history if initiated by system (user initiated changes are logged separately)
    return if content[:symptom_onset] == patient[:symptom_onset] || initiator != :system

    comment = if !patient[:symptom_onset].nil? && !content[:symptom_onset].nil?
                "System changed Symptom Onset Date from #{patient[:symptom_onset].strftime('%m/%d/%Y')} to #{content[:symptom_onset].strftime('%m/%d/%Y')}
                because monitoree was moved from isolation to exposure workflow. This allows the system to show monitoree on appropriate line list based on
                daily reports."
              elsif patient[:symptom_onset].nil? && !content[:symptom_onset].nil?
                "System changed Symptom Onset Date from blank to #{content[:symptom_onset].strftime('%m/%d/%Y')} because monitoree was moved from isolation to
                exposure workflow. This allows the system to show monitoree on appropriate line list based on daily reports."
              elsif !patient[:symptom_onset].nil? && content[:symptom_onset].nil?
                "System cleared Symptom Onset Date from #{patient[:symptom_onset].strftime('%m/%d/%Y')} to blank because monitoree was moved from isolation to
                exposure workflow. This allows the system to show monitoree on appropriate line list based on daily reports."
              else
                'System changed Symptom Onset Date. This allows the system to show monitoree on appropriate line list based on daily reports.'
              end
    History.monitoring_change(patient: patient, created_by: 'Sara Alert System', comment: comment)
  end

  def clear_assessments
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patient = current_user.get_patient(params.permit(:id)[:id])
    patient.assessments.each do |assessment|
      assessment.symptomatic = false
      assessment.save!
    end
    comment = 'User reviewed all reports.'
    comment += ' Reason: ' + params.permit(:reasoning)[:reasoning] unless params.permit(:reasoning)[:reasoning].blank?
    History.reports_reviewed(patient: patient, created_by: current_user.email, comment: comment)
  end

  def clear_assessment
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patient = current_user.get_patient(params.permit(:id)[:id])
    assessment = patient.assessments.find_by(id: params.permit(:assessment_id)[:assessment_id])

    assessment.symptomatic = false
    assessment.save!

    comment = 'User reviewed a report (ID: ' + assessment.id.to_s + ').'
    comment += ' Reason: ' + params.permit(:reasoning)[:reasoning] unless params.permit(:reasoning)[:reasoning].blank?
    History.report_reviewed(patient: patient, created_by: current_user.email, comment: comment)
  end

  # Get all individuals whose responder_id = id, these people are "HOH eligible"
  def self_reporting
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patients = if current_user.role?(Roles::ENROLLER)
                 current_user.enrolled_patients.where('patients.responder_id = patients.id')
               else
                 current_user.viewable_patients.where('patients.responder_id = patients.id')
               end
    patients = patients.pluck(:id, :first_name, :last_name, :age, :user_defined_id_statelocal).map do |p|
      { id: p[0], first_name: p[1], last_name: p[2], age: p[3], state_id: p[4] }
    end
    render json: { self_reporting: patients.sort_by { |p| p[:last_name] || 'ZZZ' }.to_json }
  end

  # A patient is eligible to be removed from a household if their responder doesn't have the same contact
  # information of them
  def household_removeable
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patient = current_user.get_patient(params.permit(:id)[:id])
    redirect_to(root_url) && return if patient.nil?

    duplicate_contact = false
    duplicate_contact = patient[:primary_telephone] == patient.responder[:primary_telephone] unless patient[:primary_telephone].blank?
    duplicate_contact ||= (patient[:email] == patient.responder[:email]) unless patient[:email].blank?
    # They are removeable from the household if their current responder does not have duplicate contact information
    render json: { removeable: !duplicate_contact }
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
      source_of_report_specify
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
      isolation
      jurisdiction_id
      assigned_user
      symptom_onset
      extended_isolation
      case_status
      continuous_exposure
      gender_identity
      sexual_orientation
      user_defined_symptom_onset
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
      source_of_report_specify
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
      isolation
      jurisdiction_id
      assigned_user
      continuous_exposure
    ]
  end

  # Fields used for updating monitoree state
  def status_fields
    %i[
      monitoring
      monitoring_reason
      monitoring_plan
      exposure_risk_assessment
      public_health_action
      isolation
      pause_notifications
      symptom_onset
      case_status
      assigned_user
      last_date_of_exposure
      continuous_exposure
      user_defined_symptom_onset
      extended_isolation
    ]
  end
end
