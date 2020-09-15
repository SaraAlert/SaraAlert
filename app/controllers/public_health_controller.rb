# frozen_string_literal: true

# PublicHealthController: handles all epi actions
class PublicHealthController < ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_user_role

  def patients
    permitted_params = params.permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :entries, :page, :order, :direction, :filter)

    # Validate workflow param
    workflow = permitted_params.require(:workflow).to_sym
    return head :bad_request unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = permitted_params.require(:tab).to_sym
    if workflow == :exposure
      return head :bad_request unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      return head :bad_request unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Validate jurisdiction param
    jurisdiction = permitted_params[:jurisdiction]
    return head :bad_request unless jurisdiction.nil? || jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(jurisdiction.to_i)

    # Validate scope param
    scope = permitted_params[:scope]&.to_sym
    return head :bad_request unless scope.nil? || %i[all exact].include?(scope)

    # Validate user param
    user = permitted_params[:user]
    return head :bad_request unless user.nil? || %w[all none].include?(user) || user.to_i.between?(1, 9999)

    # Validate search param
    search = permitted_params[:search]

    # Validate pagination params
    entries = permitted_params[:entries]&.to_i || 25
    page = permitted_params[:page]&.to_i || 0
    return head :bad_request unless entries >= 0 && page >= 0

    # Validate sort params
    order = permitted_params[:order]
    return head :bad_request unless order.nil? || order.blank? || %w[name jurisdiction transferred_from transferred_to assigned_user state_local_id dob
                                                                     end_of_monitoring risk_level monitoring_plan public_health_action expected_purge_date
                                                                     reason_for_closure closed_at transferred_at latest_report symptom_onset
                                                                     extended_isolation].include?(order)

    direction = permitted_params[:direction]
    return head :bad_request unless direction.nil? || direction.blank? || %w[asc desc].include?(direction)
    return head :bad_request unless (!order.blank? && !direction.blank?) || (order.blank? && direction.blank?)

    # Get patients by workflow and tab
    patients = patients_by_type(workflow, tab)

    # Filter by assigned jurisdiction
    unless jurisdiction.nil? || jurisdiction == 'all' || tab == :transferred_out
      jur_id = jurisdiction.to_i
      patients = scope == :all ? patients.where(jurisdiction_id: Jurisdiction.find(jur_id).subtree_ids) : patients.where(jurisdiction_id: jur_id)
    end

    # Filter by assigned user
    patients = patients.where(assigned_user: user == 'none' ? nil : user.to_i) unless user.nil? || user == 'all'

    # Filter by search text
    patients = filter(patients, search)

    # Filter by advanced filter (if present)
    if params[:filter].present?
      advanced = params.require(:filter).collect do |filter|
        {
          filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, options: []),
          value: filter.require(:value),
          dateOption: filter.permit(:dateOption)[:dateOption]
        }
      end
      patients = advanced_filter(patients, advanced) unless advanced.nil?
    end

    # Sort
    patients = sort(patients, order, direction)

    # Paginate
    patients = patients.paginate(per_page: entries, page: page + 1)

    # Extract only relevant fields to be displayed by workflow and tab
    render json: linelist(patients, workflow, tab)
  end

  # Get patient counts by workflow
  def workflow_counts
    render json: {
      exposure: current_user.viewable_patients.where(isolation: false, purged: false).size,
      isolation: current_user.viewable_patients.where(isolation: true, purged: false).size
    }
  end

  # Get counts for patients under the given workflow and tab
  def tab_counts
    # Validate workflow param
    workflow = params.require(:workflow).to_sym
    return head :bad_request unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = params.require(:tab).to_sym
    if workflow == :exposure
      return head :bad_request unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      return head :bad_request unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Get patients by workflow and tab
    patients = patients_by_type(workflow, tab)

    render json: { total: patients.size }
  end

  protected

  def patients_by_type(workflow, tab)
    return current_user.viewable_patients.where(isolation: workflow == :isolation, purged: false) if tab == :all
    return current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: workflow == :isolation) if tab == :closed
    return current_user.jurisdiction.transferred_in_patients.where(isolation: workflow == :isolation) if tab == :transferred_in
    return current_user.jurisdiction.transferred_out_patients.where(isolation: workflow == :isolation) if tab == :transferred_out

    if workflow == :exposure
      return current_user.viewable_patients.exposure_symptomatic if tab == :symptomatic
      return current_user.viewable_patients.exposure_non_reporting if tab == :non_reporting
      return current_user.viewable_patients.exposure_asymptomatic if tab == :asymptomatic
      return current_user.viewable_patients.exposure_under_investigation if tab == :pui
    else
      return current_user.viewable_patients.isolation_requiring_review if tab == :requiring_review
      return current_user.viewable_patients.isolation_non_reporting if tab == :non_reporting
      return current_user.viewable_patients.isolation_reporting if tab == :reporting
    end
  end

  def filter(patients, search)
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

    case order
    when 'name'
      patients = patients.order(last_name: dir).order(first_name: dir)
    when 'jurisdiction'
      patients = patients.includes(:jurisdiction).order('jurisdictions.name ' + dir)
    when 'transferred_from'
      patients = patients.joins('INNER JOIN jurisdictions ON jurisdictions.id = patients.latest_transfer_from').order('jurisdictions.path ' + dir)
    when 'transferred_to'
      patients = patients.includes(:jurisdiction).order('jurisdictions.path ' + dir)
    when 'assigned_user'
      patients = patients.order('CASE WHEN assigned_user IS NULL THEN 1 ELSE 0 END, assigned_user ' + dir)
    when 'state_local_id'
      patients = patients.order('CASE WHEN user_defined_id_statelocal IS NULL THEN 1 ELSE 0 END, user_defined_id_statelocal ' + dir)
    when 'dob'
      patients = patients.order('CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END, date_of_birth ' + dir)
    when 'end_of_monitoring'
      patients = patients.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + dir)
    when 'extended_isolation'
      patients = patients.order('CASE WHEN extended_isolation IS NULL THEN 1 ELSE 0 END, extended_isolation ' + dir)
    when 'symptom_onset'
      patients = patients.order('CASE WHEN symptom_onset IS NULL THEN 1 ELSE 0 END, symptom_onset ' + dir)
    when 'risk_level'
      patients = patients.order_by_risk(asc: dir == 'asc')
    when 'monitoring_plan'
      patients = patients.order('CASE WHEN monitoring_plan IS NULL THEN 1 ELSE 0 END, monitoring_plan ' + dir)
    when 'public_health_action'
      patients = patients.order('CASE WHEN public_health_action IS NULL THEN 1 ELSE 0 END, public_health_action ' + dir)
    when 'expected_purge_date'
      patients = patients.order('CASE WHEN last_date_of_exposure IS NULL THEN 1 ELSE 0 END, last_date_of_exposure ' + dir)
    when 'reason_for_closure'
      patients = patients.order('CASE WHEN monitoring_reason IS NULL THEN 1 ELSE 0 END, monitoring_reason ' + dir)
    when 'closed_at'
      patients = patients.order('CASE WHEN closed_at IS NULL THEN 1 ELSE 0 END, closed_at ' + dir)
    when 'transferred_at'
      patients = patients.order('CASE WHEN latest_transfer_at IS NULL THEN 1 ELSE 0 END, latest_transfer_at ' + dir)
    when 'latest_report'
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
    patients = patients.select('patients.id, patients.first_name, patients.last_name, patients.user_defined_id_statelocal, patients.symptom_onset, '\
                               'patients.date_of_birth, patients.assigned_user, patients.exposure_risk_assessment, patients.monitoring_plan, '\
                               'patients.public_health_action, patients.monitoring_reason, patients.closed_at, patients.last_date_of_exposure, '\
                               'patients.created_at, patients.updated_at, patients.latest_assessment_at, patients.latest_transfer_at, '\
                               'patients.continuous_exposure, jurisdictions.name AS jurisdiction_name, jurisdictions.path AS jurisdiction_path')

    # execute query and get total count
    total = patients.total_entries

    linelist = []
    patients.each do |patient|
      # populate fields common to all linelists
      details = {
        id: patient[:id],
        name: patient.displayed_name,
        state_local_id: patient[:user_defined_id_statelocal] || '',
        dob: patient[:date_of_birth]&.strftime('%F') || ''
      }

      # populate fields specific to this linelist only if relevant
      details[:jurisdiction] = patient[:jurisdiction_name] || '' if fields.include?(:jurisdiction)
      details[:transferred_from] = patient[:jurisdiction_path] || '' if fields.include?(:transferred_from)
      details[:transferred_to] = patient[:jurisdiction_path] || '' if fields.include?(:transferred_to)
      details[:assigned_user] = patient[:assigned_user] || '' if fields.include?(:assigned_user)
      details[:end_of_monitoring] = patient.end_of_monitoring || '' if fields.include?(:end_of_monitoring)
      details[:extended_isolation] = patient[:extended_isolation] if fields.include?(:extended_isolation)
      details[:symptom_onset] = patient.symptom_onset if fields.include?(:symptom_onset)
      details[:risk_level] = patient[:exposure_risk_assessment] || '' if fields.include?(:risk_level)
      details[:monitoring_plan] = patient[:monitoring_plan] || '' if fields.include?(:monitoring_plan)
      details[:public_health_action] = patient[:public_health_action] || '' if fields.include?(:public_health_action)
      details[:expected_purge_date] = patient.expected_purge_date || '' if fields.include?(:expected_purge_date)
      details[:reason_for_closure] = patient[:monitoring_reason] || '' if fields.include?(:reason_for_closure)
      details[:closed_at] = patient[:closed_at]&.rfc2822 || '' if fields.include?(:closed_at)
      details[:transferred_at] = patient[:latest_transfer_at]&.rfc2822 || '' if fields.include?(:transferred_at)
      details[:latest_report] = patient[:latest_assessment_at]&.rfc2822 || '' if fields.include?(:latest_report)
      details[:status] = patient.status.to_s.gsub('_', ' ').gsub('exposure ', '')&.gsub('isolation ', '') if fields.include?(:status)
      details[:report_eligibility] = patient.report_eligibility if fields.include?(:report_eligibility)
      details[:is_hoh] = patient.dependents_exclude_self.exists?

      linelist << details
    end

    { linelist: linelist, fields: %i[name state_local_id dob].concat(fields), total: total }
  end

  def linelist_specific_fields(workflow, tab)
    return %i[jurisdiction assigned_user expected_purge_date reason_for_closure closed_at] if tab == :closed

    if workflow == :isolation
      return %i[jurisdiction assigned_user extended_isolation symptom_onset monitoring_plan latest_report status report_eligibility] if tab == :all
      return %i[transferred_from monitoring_plan transferred_at] if tab == :transferred_in
      return %i[transferred_to monitoring_plan transferred_at] if tab == :transferred_out

      return %i[jurisdiction assigned_user extended_isolation symptom_onset monitoring_plan latest_report report_eligibility]
    end

    return %i[jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report status report_eligibility] if tab == :all
    return %i[jurisdiction assigned_user end_of_monitoring risk_level public_health_action latest_report report_eligibility] if tab == :pui
    return %i[transferred_from end_of_monitoring risk_level monitoring_plan transferred_at] if tab == :transferred_in
    return %i[transferred_to end_of_monitoring risk_level monitoring_plan transferred_at] if tab == :transferred_out

    %i[jurisdiction assigned_user end_of_monitoring risk_level monitoring_plan latest_report report_eligibility]
  end

  def advanced_filter(patients, filters)
    filters.each do |filter|
      case filter[:filterOption]['name']
      when 'sent-today'
        patients = patients.where("last_assessment_reminder_sent #{filter[:value] ? '>' : '<'} ?", DateTime.now.beginning_of_day)
      when 'responded-today'
        patients = patients.where("latest_assessment_at #{filter[:value] ? '>' : '<'} ?", DateTime.now.beginning_of_day)
      when 'paused'
        patients = patients.where('pause_notifications = ?', filter[:value])
      when 'preferred-contact-method'
        patients = patients.where('preferred_contact_method = ?', filter[:value])
      when 'latest-report'
        if filter[:dateOption] == 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('latest_assessment_at < ?', compare_date)
        elsif filter[:dateOption] == 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('latest_assessment_at > ?', compare_date)
        elsif filter[:dateOption] == 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('latest_assessment_at > ?', compare_date_start).where('latest_assessment_at < ?', compare_date_end)
        end
      when 'hoh'
        patients = if filter[:value]
                     patients.where('responder_id == id')
                   else
                     patients.where.not('responder_id == id')
                   end
      when 'enrolled'
        if filter[:dateOption] == 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('created_at < ?', compare_date)
        elsif filter[:dateOption] == 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('created_at > ?', compare_date)
        elsif filter[:dateOption] == 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('created_at > ?', compare_date_start).where('created_at < ?', compare_date_end)
        end
      when 'last-date-exposure'
        if filter[:dateOption] == 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('last_date_of_exposure < ?', compare_date)
        elsif filter[:dateOption] == 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('last_date_of_exposure > ?', compare_date)
        elsif filter[:dateOption] == 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('last_date_of_exposure > ?', compare_date_start).where('last_date_of_exposure < ?', compare_date_end)
        end
      when 'symptom-onset'
        if filter[:dateOption] == 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('symptom_onset < ?', compare_date)
        elsif filter[:dateOption] == 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('symptom_onset > ?', compare_date)
        elsif filter[:dateOption] == 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('symptom_onset > ?', compare_date_start).where('symptom_onset < ?', compare_date_end)
        end
      when 'continous-exposure'
        patients = patients.where('continuous_exposure = ?', filter[:value])
      when 'telephone-number'
        patients = patients.where('patients.primary_telephone like ?', Phonelib.parse(filter[:value], 'US').full_e164)
      when 'email'
        patients = patients.where('patients.email like ?', filter[:value])
      when 'sara-id'
        patients = patients.where(id: filter[:value])
      when 'first-name'
        patients = patients.where('patients.first_name like ?', filter[:value])
      when 'middle-name'
        patients = patients.where('patients.middle_name like ?', filter[:value])
      when 'last-name'
        patients = patients.where('patients.last_name like ?', filter[:value])
      when 'monitoring-plan'
        patients = patients.where('monitoring_plan = ?', filter[:value])
      when 'never-responded'
        patients = patients.where('last_assessment_at = ?', nil)
      when 'risk-exposure'
        patients = patients.where('exposure_risk_assessment = ?', filter[:value])
      when 'require-interpretation'
        patients = patients.where('interpretation_required = ?', filter[:value])
      when 'preferred-contact-time'
        patients = patients.where('preferred_contact_time = ?', filter[:value])
      end
    end
    patients
  end

  private

  def authenticate_user_role
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?
  end
end
