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

    # Validate workflow param
    workflow = params.permit(:workflow)[:workflow].to_sym
    redirect_to(root_url) && return unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = params.permit(:tab)[:tab].to_sym
    if workflow == :exposure
      redirect_to(root_url) && return unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      redirect_to(root_url) && return unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Validate jurisdiction param
    jurisdiction = params.permit(:jurisdiction)[:jurisdiction]
    redirect_to(root_url) && return unless jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(jurisdiction.to_i)

    # Validate scope param
    scope = params.permit(:scope)[:scope].to_sym
    redirect_to(root_url) && return unless %i[all exact].include?(scope)

    # Validate user param
    user = params.permit(:user)[:user]
    redirect_to(root_url) && return unless %w[all none].include?(user) || user.to_i.between?(1, 9999)

    # Validate pagination params
    entries = params[:entries]&.to_i || 15
    page = params[:page]&.to_i || 0
    redirect_to(root_url) && return unless entries >= 0 && page >= 0

    # Get patients by workflow and tab
    patients = patients_by_type(workflow, tab)

    # Filter by assigned jurisdiction
    unless jurisdiction == 'all' || tab == :transferred_out
      jur_id = jurisdiction.to_i
      patients = scope == :all ? patients.where(jurisdiction_id: Jurisdiction.find(jur_id).subtree_ids) : patients.where(jurisdiction_id: jur_id)
    end

    # Filter by assigned user
    patients = patients.where(assigned_user: user == 'none' ? nil : user.to_i) unless user == 'all'

    # Filter by search text
    patients = search(patients, params[:search])

    # Sort
    sorted_patients = sort(patients, params[:order], params[:columns])

    # Paginate
    paginated_patients = sorted_patients.paginate(per_page: entries, page: page + 1)

    # Extract only relevant fields to be displayed by workflow and tab
    render json: linelist(paginated_patients.to_a, workflow, tab).merge({ total: patients.size })
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

    # Validate workflow param
    workflow = params.permit(:workflow)[:workflow].to_sym
    redirect_to(root_url) && return unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = params.permit(:tab)[:tab].to_sym
    if workflow == :exposure
      redirect_to(root_url) && return unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      redirect_to(root_url) && return unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Get patients by workflow and tab
    patients = patients_by_type(workflow, tab)

    render json: { count: patients.size }
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

    patients
  end

  def sort(patients, order, columns)
    return patients if order.nil? || order.empty?

    sorted = patients
    order.each do |_num, val|
      next if columns.nil? || val.nil? || val['column'].blank? || columns[val['column']].nil?
      next if columns[val['column']][:name].blank?

      direction = val['dir'] == 'asc' ? :asc : :desc
      if columns[val['column']][:name] == 'name' # Name
        sorted = sorted.order(last_name: direction).order(first_name: direction)
      elsif columns[val['column']][:name] == 'jurisdiction' # Jurisdiction
        sorted = sorted.includes(:jurisdiction).order('jurisdictions.name ' + direction.to_s)
      elsif columns[val['column']][:name] == 'assigned_user' # Assigned User
        sorted = sorted.order('CASE WHEN assigned_user IS NULL THEN 1 ELSE 0 END, assigned_user ' + direction.to_s)
      elsif columns[val['column']][:name] == 'state_local_id' # State/Local ID
        sorted = sorted.order('CASE WHEN user_defined_id_statelocal IS NULL THEN 1 ELSE 0 END, user_defined_id_statelocal ' + direction.to_s)
      elsif columns[val['column']][:name] == 'sex' # Sex
        sorted = sorted.order('CASE WHEN sex IS NULL THEN 1 ELSE 0 END, sex ' + direction.to_s)
      elsif columns[val['column']][:name] == 'dob' # DOB
        sorted = sorted.order('CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END, date_of_birth ' + direction.to_s)
      elsif columns[val['column']][:name] == 'end_of_monitoring' # End of Monitoring
        sorted = sorted.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + direction.to_s)
      elsif columns[val['column']][:name] == 'expected_purge_date' # Expected Purge Date
        sorted = sorted.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + direction.to_s)
      elsif columns[val['column']][:name] == 'risk' # Risk
        sorted = sorted.order_by_risk(val['dir'] == 'asc')
      elsif columns[val['column']][:name] == 'monitoring_plan' # Monitoring Plan
        sorted = sorted.order('CASE WHEN monitoring_plan IS NULL THEN 1 ELSE 0 END, monitoring_plan ' + direction.to_s)
      elsif columns[val['column']][:name] == 'monitoring_reason' # Reason
        sorted = sorted.order('CASE WHEN monitoring_reason IS NULL THEN 1 ELSE 0 END, monitoring_reason ' + direction.to_s)
      elsif columns[val['column']][:name] == 'public_health_action' # PHA
        sorted = sorted.order('CASE WHEN public_health_action IS NULL THEN 1 ELSE 0 END, public_health_action ' + direction.to_s)
      elsif columns[val['column']][:name] == 'latest_report' # Latest Report
        sorted = sorted.left_outer_joins(:assessments).order('assessments.created_at ' + direction.to_s)
      elsif columns[val['column']][:name] == 'closed_at' # Closed At
        sorted = sorted.order('CASE WHEN closed_at IS NULL THEN 1 ELSE 0 END, closed_at ' + direction.to_s)
      end
    end
    sorted
  end

  def linelist(patients, workflow, tab)
    # get a list of fields relevant only to this linelist
    fields = linelist_specific_fields(workflow, tab)

    # only compute statuses if necessary
    if fields.include?(:status)
      statuses = workflow == :exposure ? get_exposure_statuses(patients) : get_isolation_statuses(patients)
    end

    # only retrieve jurisdiction if necessary
    jurisdiction_names = get_jurisdiction_names(patients) if fields.include?(:jurisdiction)

    # only retrieve assessments if necessary
    latest_assessments = get_latest_assessments(patients) if fields.include?(:latest_report)

    # only retrieve transfers if necessary
    if fields.include?(:transferred_at) || fields.include?(:transferred_from) || fields.include?(:transferred_to)
      latest_transfers = get_latest_transfers(patients)
    end

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

      details[:jurisdiction] = jurisdiction_names[patient[:id]] || '' if fields.include?(:jurisdiction)
      details[:latest_report] = latest_assessments[patient[:id]]&.rfc2822 || '' if fields.include?(:latest_report)
      details[:transferred_at] = latest_transfers[patient[:id]][:transferred_at]&.rfc2822 || '' if fields.include?(:transferred_at)
      details[:transferred_from] = latest_transfers[patient[:id]][:transferred_from] || '' if fields.include?(:transferred_from)
      details[:transferred_to] = latest_transfers[patient[:id]][:transferred_to] || '' if fields.include?(:transferred_to)
      details[:status] = statuses[patient[:id]] || '' if fields.include?(:status)

      linelist << details
    end

    { linelist: linelist, fields: %i[name state_local_id sex dob].concat(fields) }
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
