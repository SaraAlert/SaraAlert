# frozen_string_literal: true

# PatientsController: handles all subject actions
class PatientsController < ApplicationController
  include PatientHelper
  include PatientQueryHelper
  include EnrollerQueryHelper

  before_action :authenticate_user!

  # Enroller view to see enrolled subjects and button to enroll new subjects
  def index
    @title = 'Enroller Dashboard'
    @possible_jurisdiction_paths = current_user.jurisdiction.subtree.pluck(:id, :path).to_h
    @all_assigned_users = current_user.patients.where.not(assigned_user: nil).pluck(:assigned_user).uniq.sort
    redirect_to(root_url) && return unless current_user.can_create_patient?
  end

  # View if monitoree cannot be viewed by the current user
  def monitoree_unavailable
    @title = 'Monitoree Unavailable'
  end

  # The single subject view
  def show
    redirect_to(root_url) && return unless current_user.can_view_patient?

    @patient = current_user.get_patient(params.permit(:id)[:id])

    # If we failed to find a subject given the id, redirect to index
    redirect_to(action: 'monitoree_unavailable', id: params[:id]) && return if @patient.nil? || @patient.purged

    @title = "#{@patient.initials_age('-')} (ID: #{@patient.id})"

    dashboard_crumb(params.permit(:nav)[:nav], @patient)

    @jurisdiction = @patient.jurisdiction
    @laboratories = @patient.laboratories.order(:created_at)
    @close_contacts = @patient.close_contacts.order(:created_at)
    @histories = @patient.histories.order(:created_at).where(deleted_by: nil).group_by { |h| h.original_comment_id || h.id }.values.reverse
    @common_exposure_cohorts = @patient.common_exposure_cohorts.order(:created_at)

    @num_pos_labs = @laboratories.count { |lab| lab[:result] == 'positive' && lab[:specimen_collection].present? }
    @calculated_symptom_onset = calculated_symptom_onset(@patient)

    @possible_jurisdiction_paths = current_user.jurisdictions_for_transfer
    @possible_assigned_users = @jurisdiction.assigned_users

    # Household members (dependents) for the HOH excluding HOH
    @dependents_exclude_hoh = @patient.dependents_exclude_self.where(purged: false)

    # All household members regardless if current patient is HOH
    @household_members = @patient.household.where(purged: false)
    @household_members_exclude_self = @household_members.where.not(id: @patient.id)

    @translations = Assessment.new.translations

    @history_types = History::HISTORY_TYPES
  end

  # Returns a new (unsaved) subject, for creating a new subject
  def new
    redirect_to(root_url) && return unless current_user.can_create_patient?

    dashboard_crumb(params.permit(:nav)[:nav] || (params.permit(:isolation)[:isolation] ? 'isolation' : 'global'), nil)
    @title = 'Enroll New Monitoree'

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
                           contact_type: 'Self',
                           preferred_contact_method: 'Unknown')
  end

  # Similar to 'new', except used for creating a new group member
  def new_group_member
    redirect_to(root_url) && return unless current_user.can_create_patient?

    @title = 'Enroll Household Member'

    # Find the hoh
    hoh = current_user.get_patient(params.permit(:id)[:id])

    # If we failed to find the hoh given the id, redirect to index
    redirect_to(root_url) && return if hoh.nil?

    dashboard_crumb(params.permit(:nav)[:nav], hoh)

    @patient = Patient.new(hoh.attributes.slice(*group_member_subset.map(&:to_s)))

    # Set the contact name to the HoH name if the HoH has contact type "Self"
    @patient.contact_name = "#{hoh.first_name} #{hoh.last_name}" if hoh.contact_type == 'Self'

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?

    @hoh_id = hoh.id
  end

  # Editing a patient
  def edit
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    @patient = current_user.get_patient(params.permit(:id)[:id])

    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if @patient.nil?

    @title = "Edit #{@patient.initials_age('-')} (ID: #{@patient.id})"

    dashboard_crumb(params.permit(:nav)[:nav], @patient)

    @dependents_exclude_hoh = @patient.dependents_exclude_self
    @propagated_fields = group_member_subset.index_with { |_field| false }
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

    # If contact type is not set, default to "Unknown"
    patient.contact_type = 'Unknown' if patient.contact_type.nil?

    # Generate submission token for assessments
    patient.submission_token = patient.new_submission_token

    # Attempt to save and continue; else if failed redirect to index
    render(json: patient.errors, status: :unprocessable_entity) && return unless patient.save

    # Send enrollment notification only to responders
    patient.send_enrollment_notification if patient.self_reporter_or_proxy?

    # Create a history for the enrollment
    History.enrollment(patient: patient, created_by: current_user.email)

    # Create histories for lab results if present
    if allowed_params[:laboratories_attributes].present?
      patient.laboratories.order(created_at: :desc).limit(allowed_params[:laboratories_attributes].size).pluck(:id).reverse_each do |laboratory_id|
        History.lab_result(patient: patient.id, created_by: current_user.email, comment: "User added a new lab result (ID: #{laboratory_id}).")
      end
    end

    # Create histories for vaccinations if presentt
    if allowed_params[:vaccines_attributes].present?
      patient.vaccines.order(created_at: :desc).limit(allowed_params[:vaccines_attributes].size).pluck(:id).reverse_each do |vaccine_id|
        History.vaccination(patient: patient.id, created_by: current_user.email, comment: "User added a new vaccination (ID: #{vaccine_id}).")
      end
    end

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
    laboratory = params.permit(laboratory: %i[id lab_type specimen_collection report result])[:laboratory]
    common_exposure_cohorts = params.permit(common_exposure_cohorts: [%i[id cohort_type cohort_name cohort_location]])[:common_exposure_cohorts]
    other_updates = {}
    # If we failed to find a subject given the id, redirect to index
    redirect_to(root_url) && return if patient.nil?

    # Update first positive lab if present
    if laboratory.present?
      # If the laboratory id is not provided, redirect to index
      redirect_to(root_url) && return unless laboratory.key?(:id)

      # If we failed to find a laboratory given the id, redirect to index
      first_positive_lab = patient.laboratories.find(laboratory[:id])
      redirect_to(root_url) && return if first_positive_lab.blank?

      first_positive_lab.update(laboratory)
      History.lab_result(patient: patient, created_by: current_user.email, comment: "User edited a lab result (ID: #{laboratory[:id]}).")
    end

    # Update common exposure cohorts if present (need to use nil? check instead of empty?/present? for deletions)
    unless common_exposure_cohorts.nil?
      original_cohort_ids = patient.common_exposure_cohorts.pluck(:id)
      updated_cohort_ids = common_exposure_cohorts.pluck(:id)
      deleted_cohort_ids = original_cohort_ids - updated_cohort_ids

      # Save old cohort data for history
      deleted_cohorts = patient.common_exposure_cohorts.where(id: deleted_cohort_ids)
      other_updates[:common_exposure_cohorts] = { created: [], updated: [], deleted: deleted_cohorts.map(&:attributes).map(&:symbolize_keys) }

      # Update cohorts
      common_exposure_cohorts.each do |cohort|
        sanitized_cohort = cohort.slice(*%i[cohort_type cohort_name cohort_location])
        if cohort[:id]
          other_updates[:common_exposure_cohorts][:updated] << [patient.common_exposure_cohorts.find_by(id: cohort[:id]), sanitized_cohort]
          patient.common_exposure_cohorts.find_by(id: cohort[:id]).update(sanitized_cohort)
        else
          other_updates[:common_exposure_cohorts][:created] << patient.common_exposure_cohorts.create(sanitized_cohort)
        end
      end

      # Delete cohorts
      deleted_cohorts.destroy_all
    end

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

    render(json: patient.errors, status: :unprocessable_entity) and return unless patient.update(content)

    allowed_fields = allowed_params&.keys&.reject { |apk| %w[jurisdiction_id assigned_user].include? apk }
    Patient.detailed_history_edit(patient_before, patient, allowed_fields, other_updates, current_user.email)
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

    if updated
      # Create history item for new HoH
      comment = "User added monitoree with Sara Alert ID #{current_patient.id} to a household. This monitoree"\
                ' will now be responsible for handling the reporting on their behalf.'
      History.monitoring_change(patient: new_hoh, created_by: current_user.email, comment: comment)

      # Create history item for current patient being moved to a household
      comment = "User added monitoree to a household. Monitoree with Sara Alert ID #{new_hoh_id} will now be responsible"\
                ' for handling the reporting on their behalf.'
      History.monitoring_change(patient: current_patient, created_by: current_user.email, comment: comment)
    else
      error_message = 'Move to household action failed: monitoree was unable to be be updated.'
      render(json: { error: error_message }, status: :bad_request) && return
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

    if updated
      # Create history item for old HoH
      comment = "User removed dependent monitoree with Sara Alert ID #{current_patient.id} from the household. This monitoree"\
                ' will no longer be responsible for handling their reporting.'
      History.monitoring_change(patient: old_hoh, created_by: current_user.email, comment: comment)

      # Create history item on current patient
      comment = "User removed monitoree from a household. Monitoree with Sara Alert ID #{old_hoh.id} will"\
                ' no longer be responsible for handling their reporting.'
      History.monitoring_change(patient: current_patient, created_by: current_user.email, comment: comment)
    else
      error_message = 'Remove from household action failed: monitoree was unable to be be updated.'
      render(json: { error: error_message }, status: :bad_request) && return
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
    household_ids = current_patient&.dependents&.where(purged: false)&.pluck(:id) || [current_patient_id]

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
    unless current_patient.dependents.where(purged: false).pluck(:id).include?(new_hoh_id)
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

    comment = "User changed head of household from monitoree with Sara Alert ID #{old_hoh.id} to monitoree with Sara Alert ID #{new_hoh_id}."\
              " Monitoree with Sara Alert ID #{new_hoh_id} will now be responsible for handling the reporting for the household."

    # Create history item for old HoH
    History.monitoring_change(patient: new_hoh, created_by: current_user.email, comment: comment)

    # Create history item for new HoH
    History.monitoring_change(patient: current_patient, created_by: current_user.email, comment: comment)
  end

  def bulk_update
    redirect_to(root_url) && return unless current_user.can_edit_patient_monitoring_info?

    # Nothing to do in this function if there isn't a list of patient ids.
    patient_ids = params.require(:ids)
    non_dependent_patient_ids = patient_ids

    # If apply to group, find dependents ids and add to id array before user accessor for validation of access
    if ActiveModel::Type::Boolean.new.cast(params.require(:apply_to_household))
      dependent_ids = current_user.patients.where(responder_id: patient_ids).pluck(:id)
      # If apply_to_household was set, and there exists a patient that has dependents in a different
      # jurisdiction - one that the user may not have access to - those patients will get filtered out.
      not_viewable = Patient.where(purged: false, responder_id: patient_ids).pluck(:id) - dependent_ids

      unless not_viewable.empty?
        responders = Patient.find(not_viewable).map(&:responder)
        responders.uniq
        render json: { error: 'Selected monitoree dependents are in a household that spans jurisidictions which you do not have access to.',
                       patients: responders }, status: :unauthorized
      end

      patient_ids = patient_ids.union(dependent_ids)
    end
    patients = current_user.get_patients(patient_ids)

    if params.permit(:bulk_edit_type)[:bulk_edit_type] == 'follow-up'
      patients.each do |patient|
        update_follow_up_flag_fields(patient, params)
      end
    else
      # For Monitorees who are closed, we don't want to update their `monitoring` status
      # Or their `isolation` value through the bulk action case status modal.
      # It is slightly more performant to pre-calculate this outside the loop below
      closed_params = params.except('monitoring', 'isolation')
      closed_params[:diffState] = closed_params[:diffState]&.without('monitoring', 'isolation')

      patients.each do |patient|
        # We never want to update closed records monitoring status via the bulk_update
        update_params = patient.monitoring ? params : closed_params
        update_monitoring_fields(patient, update_params, non_dependent_patient_ids.include?(patient[:id]) ? patient.id : patient.responder_id,
                                 update_params[:apply_to_household] ? :group : :none)
      end
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
    update_monitoring_fields(patient, params, patient.id, :none)

    # Grab the patient IDs of houshold members to also update
    apply_to_household_ids = find_household_ids(patient, params)
    # If not applying to household, return
    return if apply_to_household_ids.empty?

    # Update selected group members if applying to household and ids are supplied
    apply_to_household_ids.each do |id|
      member = current_user.get_patient(id)
      update_monitoring_fields(member, params, patient.id, :none) unless member.nil?
    end
  end

  # Make updates to "monitoring fields" and create corresponding History items.
  # "Monitoring fields" are defined in PatientHelper.monitoring_fields
  #
  # patient - The Patient to update.
  # params - The request params.
  # initiator_id - Indicates the id of the record that was originally modified to cause the change, for instance if the change was propagated to the patient.
  # propogation - Indicates why the updates are being propogated to the Patient.
  def update_monitoring_fields(patient, params, initiator_id, propagation)
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

    # Create first positive lab and history if present
    create_lab_result(params, patient, true)

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
      initiator_id: initiator_id,
      propagation: propagation,
      reason: params[:reasoning]
    }

    patient.monitoring_history_edit(history_data, diff_state)
  end

  # Update the patient's follow-up flag fields
  def update_follow_up_flag
    redirect_to(root_url) && return unless current_user.can_edit_patient_monitoring_info?

    patient = current_user.get_patient(params.permit(:id)[:id])
    redirect_to(root_url) && return if patient.nil?

    update_follow_up_flag_fields(patient, params)
  end

  # Make updates to follow-up flag reason and/or note and create corresponding History items.
  #
  # patient - The Patient to update.
  # params - The request params.
  def update_follow_up_flag_fields(patient, params)
    clear_flag = params.permit(:clear_flag)[:clear_flag]
    history_data = {}
    if clear_flag
      clear_flag_reason = params.permit(:clear_flag_reason)[:clear_flag_reason]
      clear_follow_up_flag(patient, patient.id, clear_flag_reason)
    else
      follow_up_reason = params.permit(:follow_up_reason)[:follow_up_reason]
      follow_up_note = params.permit(:follow_up_note)[:follow_up_note]

      # Handle creating history items based on the updates
      history_data = {
        created_by: current_user.email,
        patient: patient,
        initiator_id: patient.id,
        follow_up_reason: follow_up_reason,
        follow_up_note: follow_up_note,
        follow_up_reason_before: patient.follow_up_reason,
        follow_up_note_before: patient.follow_up_note
      }

      # Handle success or failure of updating a follow-up flag
      ActiveRecord::Base.transaction do
        # Apply and save updates to the db
        patient.update!(follow_up_reason: follow_up_reason, follow_up_note: follow_up_note)
        # Create history item on successful update
        History.follow_up_flag_edit(history_data)
      end
    end

    # Grab the patient IDs of houshold members to also update
    apply_to_household_ids = find_household_ids(patient, params)
    # If not applying to household, return
    return if apply_to_household_ids.empty?

    # Update selected group members if applying to household and ids are supplied
    if clear_flag
      apply_to_household_ids.each do |id|
        member = current_user.get_patient(id)
        next if member.nil?

        clear_flag_reason = params.permit(:clear_flag_reason)[:clear_flag_reason]
        clear_follow_up_flag(member, patient.id, clear_flag_reason)
      end
    else
      apply_to_household_ids.each do |id|
        member = current_user.get_patient(id)
        next if member.nil?

        history_data[:patient] = member
        history_data[:follow_up_reason_before] = member.follow_up_reason
        history_data[:follow_up_note_before] = member.follow_up_note

        # Handle success or failure of updating a follow-up flag
        ActiveRecord::Base.transaction do
          # Apply and save updates to the db
          member.update!(follow_up_reason: follow_up_reason, follow_up_note: follow_up_note)
          # Create history item on successful update
          History.follow_up_flag_edit(history_data)
        end
      end
    end
  end

  # Clear the patient's follow-up flag reason and/or note and create corresponding History items.
  #
  # patient - The Patient to update.
  # clear_flag_reason - The note to include in the history item
  def clear_follow_up_flag(patient, initiator_id, clear_flag_reason)
    # Prep data needed to create history items based on this update
    history_data = {
      created_by: current_user.email,
      patient: patient,
      initiator_id: initiator_id,
      clear_flag_reason: clear_flag_reason,
      follow_up_reason_before: patient.follow_up_reason
    }

    # Handle success or failure of clearing a follow-up flag
    ActiveRecord::Base.transaction do
      # Apply and save updates to the db
      patient.update!(follow_up_reason: nil, follow_up_note: nil)
      # Create history item on successful update
      History.clear_follow_up_flag(history_data)
    end
  end

  def clear_assessments
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    permitted_params = params.permit(:id, :symptom_onset, :user_defined_symptom_onset, :reasoning, diffState: [])

    patient = current_user.get_patient(permitted_params[:id])
    patient.assessments.update(symptomatic: false)

    # Update symptom onset when reviewing reports in isolation
    isolation_updates = permitted_params[:diffState].map(&:to_sym) & %i[symptom_onset user_defined_symptom_onset]
    patient.update(permitted_params.transform_keys(&:to_sym).slice(*isolation_updates)) if patient.isolation && isolation_updates.any?

    # Create first positive lab if present
    lab_id = create_lab_result(params, patient, false)

    comment = 'User reviewed all reports'
    comment += " and updated Symptom Onset Date to #{patient[:symptom_onset]&.strftime('%m/%d/%Y')}" if isolation_updates.include?(:symptom_onset)
    comment += " and added a new lab result (ID: #{lab_id})" if lab_id.present?
    comment += '.'
    comment += ' Reason: ' + permitted_params[:reasoning] if permitted_params[:reasoning].present?
    History.reports_reviewed(patient: patient, created_by: current_user.email, comment: comment)
  end

  def clear_assessment
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    permitted_params = params.permit(:id, :assessment_id, :symptom_onset, :user_defined_symptom_onset, :reasoning, diffState: [])

    patient = current_user.get_patient(permitted_params[:id])
    assessment = patient.assessments.find_by(id: permitted_params[:assessment_id])
    assessment.update(symptomatic: false)

    # Update symptom onset when reviewing reports in isolation
    isolation_updates = permitted_params[:diffState].map(&:to_sym) & %i[symptom_onset user_defined_symptom_onset]
    patient.update(permitted_params.transform_keys(&:to_sym).slice(*isolation_updates)) if patient.isolation && isolation_updates.any?

    # Create first positive lab if present
    lab_id = create_lab_result(params, patient, false)

    comment = 'User reviewed a report (ID: ' + assessment.id.to_s + ')'
    comment += " and updated Symptom Onset Date to #{patient[:symptom_onset]&.strftime('%m/%d/%Y')}" if isolation_updates.include?(:symptom_onset)
    comment += " and added a new lab result (ID: #{lab_id})" if lab_id.present?
    comment += '.'
    comment += ' Reason: ' + permitted_params[:reasoning] if permitted_params[:reasoning].present?
    History.report_reviewed(patient: patient, created_by: current_user.email, comment: comment)
  end

  # Return the patient IDs of household members that need to be updated
  #
  # patient - The Patient being updated
  # params - The request params.
  def find_household_ids(patient, params)
    apply_to_household_ids = params.permit(apply_to_household_ids: [])[:apply_to_household_ids]
    if params.permit(:apply_to_household)[:apply_to_household] && !apply_to_household_ids.nil?
      # If a household member has been removed, they should not be updated
      current_household_ids = patient.household.where(purged: false).where.not(id: patient.id).pluck(:id)
      diff_household_array = apply_to_household_ids - current_household_ids
      unless diff_household_array.empty?
        error_message = 'Apply to household action failed: changes have been made to this household. Please refresh.'
        render(json: { error: error_message }, status: :bad_request)
        apply_to_household_ids = []
      end
    else
      # When not applying the change to other household members, don't return any household IDs
      apply_to_household_ids = []
    end
    apply_to_household_ids
  end

  # Create first positive lab and history if present (using laboratories_attributes does not work in this case)
  def create_lab_result(params, patient, create_history)
    return if params[:first_positive_lab].blank?

    lab = Laboratory.new(lab_type: params[:first_positive_lab][:lab_type],
                         specimen_collection: params[:first_positive_lab][:specimen_collection],
                         report: params[:first_positive_lab][:report],
                         result: params[:first_positive_lab][:result],
                         patient_id: patient.id)

    # Create history item on successful create
    ActiveRecord::Base.transaction do
      if lab.save && create_history
        History.lab_result(patient: patient.id, created_by: current_user.email, comment: "User added a new lab result (ID: #{lab.id}).")
      end
    end

    lab.id
  end

  # A patient is eligible to be removed from a household if their responder doesn't have the same contact
  # information of them
  def household_removeable
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patient = current_user.get_patient(params.permit(:id)[:id])
    redirect_to(root_url) && return if patient.nil?

    duplicate_contact = false
    duplicate_contact = patient[:primary_telephone] == patient.responder[:primary_telephone] if patient[:primary_telephone].present?
    duplicate_contact ||= (patient[:email] == patient.responder[:email]) if patient[:email].present?
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
    unique_pha = patients.distinct.pluck(:public_health_action)
    pui_elidgible = !(unique_pha.empty? || (unique_pha.length == 1 && unique_pha.include?('None')))
    render json: { case_status: patients.pluck(:case_status), isolation: patients.pluck(:isolation), monitoring: patients.pluck(:monitoring),
                   monitoring_reason: patients.pluck(:monitoring_reason), pui_elidgible: pui_elidgible }
  end

  # Fetches table data for viable HoH options.
  def head_of_household_options
    begin
      patients = patients_table_data(params, current_user)
    rescue InvalidQueryError => e
      return render json: e, status: :bad_request
    end

    render json: patients
  end

  # Fetches table data for enrollers
  def enrolled_patients
    begin
      patients = enroller_table_data(params, current_user)
    rescue InvalidQueryError => e
      return render json: e, status: :bad_request
    end

    render json: patients
  end

  private

  # Set the instance variables necessary for rendering the breadcrumbs
  def dashboard_crumb(dashboard, patient)
    unless current_user.enroller?
      @dashboard = %w[global isolation exposure].include?(dashboard) ? dashboard : (patient&.isolation ? 'isolation' : 'exposure')
    end

    @dashboard_path = case @dashboard
                      when 'isolation'
                        public_health_isolation_path
                      when 'exposure'
                        public_health_exposure_path
                      else
                        current_user.enroller? ? patients_path : public_health_global_path
                      end
  end
end
