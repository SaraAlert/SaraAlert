# frozen_string_literal: true

# PatientsController: handles all subject actions
class PatientsController < ApplicationController
  include PatientQueryHelper

  before_action :authenticate_user!

  # Enroller view to see enrolled subjects and button to enroll new subjects
  def index
    @enrolled_patients = current_user.enrolled_patients.eager_load(:jurisdiction)
    redirect_to(root_url) && return unless current_user.can_create_patient?
  end

  # The single subject view
  def show
    redirect_to(root_url) && return unless current_user.can_view_patient?

    @patient = current_user.get_patient(params.permit(:id)[:id])

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?

    @laboratories = @patient.laboratories.order(:created_at)
    @close_contacts = @patient.close_contacts.order(:created_at)

    @possible_jurisdiction_paths = current_user.jurisdictions_for_transfer

    # Household members (dependents) for the HOH excluding HOH
    @dependents_exclude_hoh = @patient.dependents_exclude_self.where(purged: false)

    # All household members regardless if current patient is HOH
    @household_members = @patient.household.where(purged: false)
    @household_members_exclude_self = @household_members.where.not(id: @patient.id)

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
                           last_date_of_exposure: @close_contact.nil? ? '' : @close_contact.last_date_of_exposure,
                           assigned_user: @close_contact.nil? ? '' : @close_contact.assigned_user,
                           contact_of_known_case: !@close_contact.nil?,
                           contact_of_known_case_id: @close_contact.nil? ? '' : @close_contact.patient_id,
                           exposure_notes: @close_contact.nil? ? '' : @close_contact.notes,
                           preferred_contact_method: 'Unknown')
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
    @enrollment_step = params.permit(:step)[:step]&.to_i
  end

  # This follows 'new', this will receive the subject details and save a new subject
  # to the database.
  def create
    redirect_to(root_url) && return unless current_user.can_create_patient? || current_user.can_import?

    # Check for potential duplicate
    unless params[:bypass_duplicate]
      duplicate_data = current_user.viewable_patients.duplicate_data_detection(allowed_params)

      render(json: duplicate_data) && return if duplicate_data[:is_duplicate]
    end

    # Add patient details that were collected from the form
    patient = Patient.new(allowed_params)

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

    # Generate submission token for assessments
    patient.submission_token = patient.new_submission_token

    # Attempt to save and continue; else if failed redirect to index
    render(json: patient.errors, status: 422) && return unless patient.save

    # Send enrollment notification only to responders
    patient.send_enrollment_notification if patient.self_reporter_or_proxy?

    # Create a history for the enrollment
    History.enrollment(patient: patient, created_by: current_user.email)

    if params[:cc_id].present?
      close_contact = CloseContact.where(patient_id: current_user.viewable_patients).where(id: params.permit(:cc_id)[:cc_id])&.first
      close_contact.update(enrolled_id: patient.id)
    end

    render(json: patient) && return
  end

  # General updates to an existing subject.
  def update
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    content = params.require(:patient).permit(:id).merge!(allowed_params)
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
        transfer = Transfer.create!(patient: patient, from_jurisdiction: patient.jurisdiction, to_jurisdiction_id: content[:jurisdiction_id], who: current_user)
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

    # Update patient history with detailed edit diff
    patient_before = patient.dup

    render(json: patient.errors, status: 422) and return unless patient.update(content)

    allowed_fields = allowed_params&.keys&.reject { |apk| %w[jurisdiction_id assigned_user].include? apk }
    Patient.detailed_history_edit(patient_before, patient, allowed_fields, current_user.email)
    # Add a history update for any changes from moving from isolation to exposure
    patient.update_patient_history_for_isolation(patient_before, content[:isolation]) unless content[:isolation].nil?

    render json: patient
  end

  # Moves a record into a household
  def move_to_household
    new_hoh_id = params.permit(:new_hoh_id)[:new_hoh_id]&.to_i
    current_patient_id = params.permit(:id)[:id]&.to_i

    current_patient = current_user.get_patient(current_patient_id)
    new_hoh = current_user.get_patient(new_hoh_id)
    current_user_patients = current_user.patients

    # ----- Error Checking -----

    # Check to make sure selected HoH record exists.
    unless current_user_patients.exists?(new_hoh_id)
      error_message = "Move to household action failed: selected Head of Household with ID #{new_hoh_id} is not accessible."
      render(json: { error: error_message }, status: :forbidden) && return
    end

    # Check to make sure user has access to update this record.
    unless current_user_patients.exists?(current_patient_id)
      error_message = 'Move to household action failed: user does not have permissions to update current monitoree.'
      render(json: { error: error_message }, status: :forbidden) && return
    end

    # Do not do anything if there hasn't been a change to the responder at all.
    redirect_to(root_url) && return if current_patient.responder_id == new_hoh_id

    # Do not allow the user to set this record as a new HoH if they are a dependent already.
    if new_hoh.responder_id != new_hoh_id
      error_message = 'Move to household action failed: selected Head of Household is not valid as they are a dependent in an existing household. '\
                      'Please refresh.'
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Don't allow a HoH to be moved to a household.
    if current_patient.head_of_household
      error_message = 'Move to household action failed: monitoree is a head of household and therefore cannot be moved to a household '\
                      'through the Move to Household action. Please refresh.'
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # ----- Record Updates -----

    # Update the record
    updated = current_patient.update(responder_id: new_hoh_id)

    if !updated
      error_message = 'Move to household action failed: monitoree was unable to be be updated.'
      render(json: { error: error_message }, status: :bad_request) && return
    else
      # Create history item for new HoH
      comment = "User added monitoree with ID #{current_patient.id} to a household. This monitoree"\
                ' will now be responsible for handling the reporting on their behalf.'
      History.monitoring_change(patient: new_hoh, created_by: current_user.email, comment: comment)

      # Create history item for current patient being moved to a household
      comment = "User added monitoree to a household. Monitoree with ID #{new_hoh_id} will now be responsible"\
                ' for handling the reporting on their behalf.'
      History.monitoring_change(patient: current_patient, created_by: current_user.email, comment: comment)
    end
  end

  # Removes a record from a household
  def remove_from_household
    current_patient_id = params.permit(:id)[:id]&.to_i

    current_patient = current_user.get_patient(current_patient_id)
    current_user_patients = current_user.patients

    # ----- Error Checking -----

    # Check to make sure user has access to update this record.
    unless current_user_patients.exists?(current_patient_id)
      error_message = 'Remove from household action failed: user does not have permissions to update current monitoree.'
      render(json: { error: error_message }, status: :forbidden) && return
    end

    # If the current patients is a HoH, they can't be removed.
    if current_patient.head_of_household
      error_message = 'Remove from household action failed: monitoree is a head of household. Please refresh.'
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # ----- Record Updates -----
    old_hoh = current_user.get_patient(current_patient.responder_id)

    # Update the record
    updated = current_patient.update(responder_id: current_patient.id)

    if !updated
      error_message = 'Remove from household action failed: monitoree was unable to be be updated.'
      render(json: { error: error_message }, status: :bad_request) && return
    else
      # Create history item for old HoH
      comment = "User removed dependent monitoree with ID #{current_patient.id} from the household. This monitoree"\
                ' will no longer be responsible for handling their reporting.'
      History.monitoring_change(patient: old_hoh, created_by: current_user.email, comment: comment)

      # Create history item on current patient
      comment = "User removed monitoree from a household. Monitoree with ID #{old_hoh.id} will"\
                ' no longer be responsible for handling their reporting.'
      History.monitoring_change(patient: current_patient, created_by: current_user.email, comment: comment)
    end
  end

  # Changes the HoH of a household
  def update_hoh
    new_hoh_id = params.permit(:new_hoh_id)[:new_hoh_id]&.to_i
    current_patient_id = params.permit(:id)[:id]

    current_patient = current_user.get_patient(current_patient_id)
    new_hoh = current_user.get_patient(new_hoh_id)
    current_user_patients = current_user.patients

    # If the current patient is not accessible, current_patient.dependents will be nil so
    # in that case we just include the current patient ID in the househld.
    household_ids = current_patient&.dependents&.pluck(:id) || [current_patient_id]

    # ----- Error Checking -----

    # Check to make sure selected HoH record exists.
    unless current_user_patients.exists?(new_hoh_id)
      error_message = "Change head of household action failed: selected Head of Household with ID #{new_hoh_id} is not accessible."
      render(json: { error: error_message }, status: :forbidden) && return
    end

    # Check to make sure user has access to update all of these records.
    unless current_user_patients.where(id: household_ids).size == household_ids.length
      error_message = 'Change head of household action failed: user does not have permissions to update current monitoree or one or more of their dependents.'
      render(json: { error: error_message }, status: :forbidden) && return
    end

    # Do not do anything if there hasn't been a change to the responder at all.
    redirect_to(root_url) && return if current_patient.responder_id == new_hoh_id

    # If the new head of household was removed from the household, don't allow the change
    unless current_patient.dependents.pluck(:id).include?(new_hoh_id)
      error_message = 'Change head of household action failed: selected Head of Household is no longer in household. Please refresh.'
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # ----- Record Updates -----
    old_hoh = current_user.get_patient(current_patient.responder_id)

    begin
      Patient.transaction do
        # Change all of the patients in the household, including the current patient to have new_hoh_id as the responder
        current_user_patients.where(id: household_ids).each do |patient|
          patient.update!(responder_id: new_hoh_id)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      error_message = 'Change head of household action failed: monitoree(s) were unable to be be updated.'
      Rails.logger.info("#{error_message} Error: #{e}")
      render(json: { error: error_message }, status: :bad_request) && return
    end

    comment = "User changed head of household from monitoree with ID #{old_hoh.id} to monitoree with ID #{new_hoh_id}."\
              " Monitoree with ID #{new_hoh_id} will now be responsible for handling the reporting for the household."

    # Create history item for old HoH
    History.monitoring_change(patient: new_hoh, created_by: current_user.email, comment: comment)

    # Create history item for new HoH
    History.monitoring_change(patient: current_patient, created_by: current_user.email, comment: comment)
  end

  def bulk_update
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
      update_monitoring_fields(patient, params, non_dependent_patient_ids.include?(patient[:id]) ? :patient : :dependent,
                               params[:apply_to_household] ? :group : :none)
    end
  end

  # Updates to workflow/tracking status for a subject
  def update_status
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patient = current_user.get_patient(params.permit(:id)[:id])
    redirect_to(root_url) && return if patient.nil?

    # Update LDE for patient and household members only in the exposure workflow with continuous exposure on
    # NOTE: This is a possible option when changing monitoring status of HoH or dependent in isolation
    if params.permit(:apply_to_household_cm_exp_only)[:apply_to_household_cm_exp_only] && params[:apply_to_household_cm_exp_only_date].present?
      # Only update household members in the exposure workflow with continuous exposure is turned on
      (current_user.get_patient(patient.responder_id)&.household&.where(continuous_exposure: true, isolation: false) || []).uniq.each do |member|
        History.monitoring_change(patient: member, created_by: 'Sara Alert System', comment: "User updated Monitoring Status for another member in this
        monitoree's household and chose to update Last Date of Exposure for household members so System changed Last Date of Exposure from
        #{member[:last_date_of_exposure] ? member[:last_date_of_exposure].to_date.strftime('%m/%d/%Y') : 'blank'} to
        #{params[:apply_to_household_cm_exp_only_date].to_date.strftime('%m/%d/%Y')} and turned OFF Continuous Exposure.")

        member.update(last_date_of_exposure: params[:apply_to_household_cm_exp_only_date], continuous_exposure: false)
      end
    end

    # Update patient
    update_monitoring_fields(patient, params, :patient, :none)

    # If not applying to household, return
    apply_to_household_ids = params.permit(apply_to_household_ids: [])[:apply_to_household_ids]
    return unless params.permit(:apply_to_household)[:apply_to_household] && !apply_to_household_ids.nil?

    # If a household member has been removed, they should not be updated
    current_household_ids = patient.household.where(purged: false).where.not(id: patient.id).pluck(:id)
    diff_household_array = apply_to_household_ids - current_household_ids
    unless diff_household_array.empty?
      error_message = 'Apply to household action failed: changes have been made to this household. Please refresh.'
      render(json: { error: error_message }, status: :bad_request) && return
    end

    # Update selected group members if applying to household and ids are supplied
    apply_to_household_ids.each do |id|
      member = current_user.get_patient(id)
      update_monitoring_fields(member, params, :patient, :none) unless member.nil?
    end
  end

  # Make updates to "monitoring fields" and create corresponding History items.
  # "Monitoring fields" are defined in PatientHelper.monitoring_fields
  #
  # patient - The Patient to update.
  # params - The request params.
  # household - Indicates if the Patient was updated directly (household = :patient) or updated because their head of household was (household = :dependent)
  # propogation - Indicates why the updates are being propogated to the Patient.
  def update_monitoring_fields(patient, params, household, propagation)
    # Figure out what exactly changed, and limit update to only those fields
    diff_state = params[:diffState]&.map(&:to_sym)
    permitted_params = if diff_state.nil?
                         PatientHelper.monitoring_fields
                       else
                         # Set intersection between what the front end is saying changed, and status fields
                         PatientHelper.monitoring_fields & diff_state
                       end
    # Transforming into hash with symbol keys for consistent parsing later on
    updates = params.require(:patient).permit(permitted_params).to_h.deep_symbolize_keys

    patient_before = patient.dup

    # Apply and save updates to the db
    patient.update!(updates)

    # If the jurisdiction was changed, create a Transfer
    if updates&.keys&.include?(:jurisdiction_id) && !updates[:jurisdiction_id].nil?
      Transfer.create(patient: patient, from_jurisdiction: patient_before.jurisdiction, to_jurisdiction: patient.jurisdiction, who: current_user)
    end

    # Handle creating history items based on the updates
    history_data = {
      created_by: current_user.email,
      patient_before: patient_before,
      patient: patient,
      updates: updates,
      household_status: household,
      propagation: propagation,
      reason: params[:reasoning]
    }

    patient.monitoring_history_edit(history_data, diff_state)
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

  # Check to see if a phone number has blocked SMS communications with SaraAlert
  def sms_eligibility_check
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    phone_number = params.require(:phone_number)
    blocked = BlockedNumber.exists?(phone_number: phone_number)
    render json: { sms_eligible: !blocked }
  end

  # Construct a diff for a patient update to keep track of changes
  def patient_diff(patient_before, patient_after)
    diffs = []
    allowed_params.each_key do |attribute|
      next if patient_before[attribute] == patient_after[attribute]

      diffs << {
        attribute: attribute,
        before: attribute == :jurisdiction_id ? Jurisdiction.find(patient_before[attribute])[:path] : patient_before[attribute],
        after: attribute == :jurisdiction_id ? Jurisdiction.find(patient_after[attribute])[:path] : patient_after[attribute]
      }
    end
    diffs
  end

  # Returns case status value(s) of the selected patient(s) so bulk update modal displays correct default value
  def current_case_status
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patient_ids = params[:patient_ids]
    patients = current_user.viewable_patients.where(id: patient_ids)
    render json: { case_status: patients.pluck(:case_status), isolation: patients.pluck(:isolation), monitoring: patients.pluck(:monitoring) }
  end

  # Fetches table data for viable HoH options.
  def head_of_household_options
    patients_table_data(params)
  end

  # Parameters allowed for saving to database
  def allowed_params
    params.require(:patient).permit(
      :user_defined_id_statelocal,
      :user_defined_id_cdc,
      :user_defined_id_nndss,
      :first_name,
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
      :race_other,
      :race_unknown,
      :race_refused_to_answer,
      :ethnicity,
      :primary_language,
      :secondary_language,
      :interpretation_required,
      :nationality,
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
      :preferred_contact_time,
      :port_of_origin,
      :source_of_report,
      :source_of_report_specify,
      :flight_or_vessel_number,
      :flight_or_vessel_carrier,
      :port_of_entry_into_usa,
      :travel_related_notes,
      :additional_planned_travel_type,
      :additional_planned_travel_destination,
      :additional_planned_travel_destination_state,
      :additional_planned_travel_destination_country,
      :additional_planned_travel_port_of_departure,
      :date_of_departure,
      :date_of_arrival,
      :additional_planned_travel_start_date,
      :additional_planned_travel_end_date,
      :additional_planned_travel_related_notes,
      :last_date_of_exposure,
      :potential_exposure_location,
      :potential_exposure_country,
      :contact_of_known_case,
      :contact_of_known_case_id,
      :travel_to_affected_country_or_area,
      :was_in_health_care_facility_with_known_cases,
      :was_in_health_care_facility_with_known_cases_facility_name,
      :laboratory_personnel,
      :laboratory_personnel_facility_name,
      :healthcare_personnel,
      :healthcare_personnel_facility_name,
      :exposure_notes,
      :crew_on_passenger_or_cargo_flight,
      :monitoring_plan,
      :exposure_risk_assessment,
      :member_of_a_common_exposure_cohort,
      :member_of_a_common_exposure_cohort_type,
      :isolation,
      :jurisdiction_id,
      :assigned_user,
      :symptom_onset,
      :extended_isolation,
      :case_status,
      :continuous_exposure,
      :gender_identity,
      :sexual_orientation,
      :user_defined_symptom_onset,
      laboratories_attributes: %i[
        lab_type
        specimen_collection
        report
        result
      ]
    )
  end

  # Fields that should be copied over from parent to group member for easier form completion
  def group_member_subset
    %i[
      address_line_1
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
      foreign_address_line_1
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
end
