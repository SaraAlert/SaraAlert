# frozen_string_literal: true

# PublicHealthController: handles all epi actions
class PublicHealthController < ApplicationController
  include PatientDetailsHelper

  before_action :authenticate_user!

  def exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?
  end

  def isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?
  end

  def patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    permitted_params = params.permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :entries, :page, :order, :direction)

    # Validate workflow param
    workflow = permitted_params[:workflow].to_sym
    redirect_to(root_url) && return unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = permitted_params[:tab].to_sym
    if workflow == :exposure
      redirect_to(root_url) && return unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      redirect_to(root_url) && return unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Validate jurisdiction param
    jurisdiction = permitted_params[:jurisdiction]
    redirect_to(root_url) && return unless jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(jurisdiction.to_i)

    # Validate scope param
    scope = permitted_params[:scope].to_sym
    redirect_to(root_url) && return unless %i[all exact].include?(scope)

    # Validate user param
    user = permitted_params[:user]
    redirect_to(root_url) && return unless %w[all none].include?(user) || user.to_i.between?(1, 9999)

    # Validate search param
    search = permitted_params[:search]

    # Validate pagination params
    entries = permitted_params[:entries]&.to_i || 15
    page = permitted_params[:page]&.to_i || 0
    redirect_to(root_url) && return unless entries >= 0 && page >= 0

    # Validate sort params
    order = permitted_params[:order]
    direction = permitted_params[:direction]
    redirect_to(root_url) && return unless ['', 'asc', 'desc'].include?(direction)

    # Get patients by workflow and tab
    patients = patients_by_type(workflow, tab)

    # Filter by assigned jurisdiction
    unless jurisdiction == 'all' || jurisdiction.to_i == current_user.jurisdiction_id || tab == :transferred_out
      jur_id = jurisdiction.to_i
      patients = scope == :all ? patients.where(jurisdiction_id: Jurisdiction.find(jur_id).subtree_ids) : patients.where(jurisdiction_id: jur_id)
    end

    # Filter by assigned user
    patients = patients.where(assigned_user: user == 'none' ? nil : user.to_i) unless user == 'all'

    # Filter by search text
    patients = search(patients, search)

    # Sort
    patients = sort(patients, order, direction)

    # Paginate
    patients = patients.paginate(per_page: entries, page: page + 1)

    # Extract only relevant fields to be displayed by workflow and tab
    render json: linelist(patients, workflow, tab)
  end

  # Get patient counts by workflow
  def workflow_counts
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    render json: {
      exposure: current_user.viewable_patients.where(isolation: false).where(purged: false).size,
      isolation: current_user.viewable_patients.where(isolation: true).where(purged: false).size
    }
  end

  # Get counts for patients under the given workflow and tab
  def patient_counts
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    permitted_params = params.permit(:workflow, :tab)

    # Validate workflow param
    workflow = permitted_params[:workflow].to_sym
    redirect_to(root_url) && return unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = permitted_params[:tab].to_sym
    if workflow == :exposure
      redirect_to(root_url) && return unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      redirect_to(root_url) && return unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Get patients by workflow and tab
    patients = patients_by_type(workflow, tab)

    render json: { total: patients.size }
  end

  # Get all individuals whose responder_id = id, these people are "HOH eligible"
  def self_reporting
    redirect_to(root_url) && return unless current_user.can_edit_patient?

    patients = if current_user.has_role?(:enroller)
                 current_user.enrolled_patients.where('patients.responder_id = patients.id')
               else
                 current_user.viewable_patients.where('patients.responder_id = patients.id')
               end
    patients = patients.pluck(:id, :first_name, :last_name, :age, :user_defined_id_statelocal).map do |p|
      { id: p[0], first_name: p[1], last_name: p[2], age: p[3], state_id: p[4] }
    end
    render json: { self_reporting: patients.to_json }
  end

  protected

  def patients_by_type(workflow, tab)
    if tab == :transferred_in
      patients = current_user.jurisdiction.transferred_in_patients.where(isolation: workflow == :isolation)
    elsif tab == :transferred_out
      patients = current_user.jurisdiction.transferred_out_patients.where(isolation: workflow == :isolation)
    else
      patients = current_user.viewable_patients

      if workflow == :exposure
        patients = patients.where(isolation: false)
        patients = patients.exposure_symptomatic if tab == :symptomatic
        patients = patients.exposure_non_reporting if tab == :non_reporting
        patients = patients.exposure_asymptomatic if tab == :asymptomatic
        patients = patients.exposure_under_investigation if tab == :pui
      else
        patients = patients.where(isolation: true)
        patients = patients.isolation_requiring_review if tab == :requiring_review
        patients = patients.isolation_non_reporting if tab == :non_reporting
        patients = patients.isolation_reporting if tab == :reporting
      end

      patients = patients.monitoring_closed_without_purged if tab == :closed
    end

    patients
  end

  def search(patients, search)
    return patients if search.nil? || search.blank?

    patients.where('first_name like ?', "#{search}%").or(
      patients.where('last_name like ?', "#{search}%").or(
        patients.where('user_defined_id_statelocal like ?', "#{search}%").or(
          patients.where('user_defined_id_cdc like ?', "#{search}%").or(
            patients.where('user_defined_id_nndss like ?', "#{search}%").or(
              patients.where('date_of_birth like ?', "#{search}%")
            )
          )
        )
      )
    )
  end

  def sort(patients, order, direction)
    return patients if order.nil? || order.empty? || direction.nil? || direction.blank?

    # Satisfy brakeman with additional sanitation logic
    dir = direction == 'asc' ? 'asc' : 'desc'

    if order == 'name'
      patients = patients.order(last_name: dir).order(first_name: dir)
    elsif order == 'jurisdiction'
      patients = patients.includes(:jurisdiction).order('jurisdictions.name ' + dir)
    elsif order == 'transferred_from'
      patients = patients.joins('INNER JOIN jurisdictions ON jurisdictions.id = patients.latest_transfer_from').order('jurisdictions.path ' + dir)
    elsif order == 'transferred_to'
      patients = patients.includes(:jurisdiction).order('jurisdictions.path ' + dir)
    elsif order == 'assigned_user'
      patients = patients.order('CASE WHEN assigned_user IS NULL THEN 1 ELSE 0 END, assigned_user ' + dir)
    elsif order == 'state_local_id'
      patients = patients.order('CASE WHEN user_defined_id_statelocal IS NULL THEN 1 ELSE 0 END, user_defined_id_statelocal ' + dir)
    elsif order == 'sex'
      patients = patients.order('CASE WHEN sex IS NULL THEN 1 ELSE 0 END, sex ' + dir)
    elsif order == 'dob'
      patients = patients.order('CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END, date_of_birth ' + dir)
    elsif order == 'end_of_monitoring'
      patients = patients.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + dir)
    elsif order == 'risk_level'
      patients = patients.order_by_risk(dir == 'asc')
    elsif order == 'monitoring_plan'
      patients = patients.order('CASE WHEN monitoring_plan IS NULL THEN 1 ELSE 0 END, monitoring_plan ' + dir)
    elsif order == 'public_health_action'
      patients = patients.order('CASE WHEN public_health_action IS NULL THEN 1 ELSE 0 END, public_health_action ' + dir)
    elsif order == 'expected_purge_date'
      patients = patients.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + dir)
    elsif order == 'reason_for_closure'
      patients = patients.order('CASE WHEN monitoring_reason IS NULL THEN 1 ELSE 0 END, monitoring_reason ' + dir)
    elsif order == 'closed_at'
      patients = patients.order('CASE WHEN closed_at IS NULL THEN 1 ELSE 0 END, closed_at ' + dir)
    elsif order == 'transferred_at'
      patients = patients.order('CASE WHEN latest_transfer_at IS NULL THEN 1 ELSE 0 END, latest_transfer_at ' + dir)
    elsif order == 'latest_report'
      patients = patients.order('CASE WHEN latest_assessment_at IS NULL THEN 1 ELSE 0 END, latest_assessment_at ' + dir)
    end

    patients
  end

  def linelist(patients, workflow, tab)
    # get a list of fields relevant only to this linelist
    fields = linelist_specific_fields(workflow, tab)

    # retrieve proper jurisdiction
    patients = if tab == :transferred_in
                 patients.joins('INNER JOIN jurisdictions ON jurisdictions.id = patients.latest_transfer_from')
               else
                 patients.joins(:jurisdiction)
               end

    # only select patient fields necessary to generate linelists
    patients = patients.select('patients.id, patients.first_name, patients.last_name, patients.user_defined_id_statelocal, patients.sex, '\
                               'patients.date_of_birth, patients.assigned_user, patients.exposure_risk_assessment, patients.monitoring_plan, '\
                               'patients.public_health_action, patients.monitoring_reason, patients.closed_at, patients.last_date_of_exposure, '\
                               'patients.created_at, patients.updated_at, patients.latest_assessment_at, patients.latest_transfer_at, '\
                               'jurisdictions.name AS jurisdiction_name, jurisdictions.path AS jurisdiction_path')

    # execute query and get total count
    total = patients.total_entries

    linelist = []
    patients.each do |patient|
      # populate fields relevant to all linelists
      name = if patient[:first_name].present? || patient[:last_name].present?
               "#{patient[:last_name]}#{patient[:first_name].blank? ? '' : ', ' + patient[:first_name]}"
             else
               'NAME NOT PROVIDED'
             end

      details = {
        id: patient[:id],
        name: name || '',
        state_local_id: patient[:user_defined_id_statelocal] || '',
        sex: patient[:sex] || '',
        dob: patient[:date_of_birth]&.strftime('%F') || ''
      }

      # populate fields specific to this linelist only if relevant
      details[:assigned_user] = patient[:assigned_user] || '' if fields.include?(:assigned_user)
      details[:risk_level] = patient[:exposure_risk_assessment] || '' if fields.include?(:risk_level)
      details[:monitoring_plan] = patient[:monitoring_plan] || '' if fields.include?(:monitoring_plan)
      details[:public_health_action] = patient[:public_health_action] || '' if fields.include?(:public_health_action)
      details[:expected_purge_date] = (patient[:updated_at] + ADMIN_OPTIONS['purgeable_after'].minutes)&.rfc2822 || '' if fields.include?(:expected_purge_date)
      details[:reason_for_closure] = patient[:monitoring_reason] || '' if fields.include?(:reason_for_closure)
      details[:closed_at] = patient[:closed_at]&.rfc2822 || '' if fields.include?(:closed_at)

      if fields.include?(:end_of_monitoring)
        details[:end_of_monitoring] = if patient[:last_date_of_exposure].present?
                                        (patient[:last_date_of_exposure] + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s
                                      elsif patient[:created_at].present?
                                        (patient[:created_at] + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s
                                      else
                                        ''
                                      end
      end

      details[:jurisdiction] = patient[:jurisdiction_name] || '' if fields.include?(:jurisdiction)
      details[:latest_report] = patient[:latest_assessment_at]&.rfc2822 || '' if fields.include?(:latest_report)
      details[:transferred_at] = patient[:latest_transfer_at]&.rfc2822 || '' if fields.include?(:transferred_at)
      details[:transferred_from] = patient[:jurisdiction_path] || '' if fields.include?(:transferred_from)
      details[:transferred_to] = patient[:jurisdiction_path] || '' if fields.include?(:transferred_to)
      details[:status] = patient.status.to_s.gsub('_', ' ').gsub('exposure ', '')&.gsub('isolation ', '') if fields.include?(:status)

      linelist << details
    end

    { linelist: linelist, fields: %i[name state_local_id sex dob].concat(fields), total: total }
  end

  def linelist_specific_fields(workflow, tab)
    return %i[jurisdiction assigned_user expected_purge_date reason_for_closure closed_at] if tab == :closed

    if workflow == :isolation
      return %i[jurisdiction assigned_user monitoring_plan latest_report status] if tab == :all
      return %i[transferred_from monitoring_plan transferred_at] if tab == :transferred_in
      return %i[transferred_to monitoring_plan transferred_at] if tab == :transferred_out

      return %i[jurisdiction assigned_user monitoring_plan latest_report]
    end

    return %i[jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report status] if tab == :all
    return %i[jurisdiction assigned_user end_of_monitoring risk_level public_health_action latest_report] if tab == :pui
    return %i[transferred_from end_of_monitoring risk_level monitoring_plan transferred_at] if tab == :transferred_in
    return %i[transferred_to end_of_monitoring risk_level monitoring_plan transferred_at] if tab == :transferred_out

    %i[jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report]
  end
end
