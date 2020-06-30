# frozen_string_literal: true

# PublicHealthController: handles all epi actions
class PublicHealthController < ApplicationController
  before_action :authenticate_user!

  def exposure
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    @exposure_count = current_user.viewable_patients.where(isolation: false).where(purged: false).size
    @isolation_count = current_user.viewable_patients.where(isolation: true).where(purged: false).size
  end

  def isolation
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    @exposure_count = current_user.viewable_patients.where(isolation: false).where(purged: false).size
    @isolation_count = current_user.viewable_patients.where(isolation: true).where(purged: false).size
  end

  def patients
    # Restrict access to public health only
    redirect_to(root_url) && return unless current_user.can_view_public_health_dashboard?

    puts params
    
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

    # Filter by workflow and tab
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

    # Filter by assigned jurisdiction
    unless jurisdiction == 'all'
      jur_id = jurisdiction.to_i
      patients = scope == :all ? patients.where(jurisdiction_id: Jurisdiction.find(jur_id).subtree_ids) : patients.where(jurisdiction_id: jur_id)
    end

    # Filter by assigned user
    patients = patients.where(assigned_user: user == 'none' ? nil : user.to_i) unless user == 'all'

    # Filter by search text
    patients = filter(patients, params[:search])

    # Sort
    patients = sort(patients, params[:order], params[:columns])

    # Paginate
    patients = paginate(patients, params[:length].to_i, params[:start].to_i)

    # Extract only relevant fields to be displayed by workflow and tab
    render json: extract_fields(patients, workflow, tab).merge({ total: patients.size })
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
        # Same as end of monitoring
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

  def paginate(patients, length, start)
    page = start.zero? ? 1 : (start / length) + 1
    patients.paginate(per_page: length, page: page)
  end

  def extract_fields(patients, workflow, tab)
    if workflow == :exposure
      return exposure_symptomatic(patients) if tab == :symptomatic
      return exposure_non_reporting(patients) if tab == :non_reporting
      return exposure_asymptomatic(patients) if tab == :asymptomatic
      return exposure_pui(patients) if tab == :pui
      return exposure_closed(patients) if tab == :closed
      return exposure_transferred_in(patients) if tab == :transferred_in
      return exposure_transferred_out(patients) if tab == :transferred_out
      return exposure_all(patients) if tab == :all
    else
      return isolation_requiring_review(patients) if tab == :requiring_review
      return isolation_non_reporting(patients) if tab == :non_reporting
      return isolation_reporting(patients) if tab == :reporting
      return isolation_closed(patients) if tab == :closed
      return isolation_transferred_in(patients) if tab == :transferred_in
      return isolation_transferred_out(patients) if tab == :transferred_out
      return isolation_all(patients) if tab == :all
    end
  end

  def exposure_symptomatic(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                'Monitoring Plan', 'Latest Report'],
      data: []
    }
  end

  def exposure_non_reporting(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                'Monitoring Plan', 'Latest Report'],
      data: []
    }
  end

  def exposure_asymptomatic(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                'Monitoring Plan', 'Latest Report'],
      data: []
    }
  end

  def exposure_pui(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                'Latest Public Health Action', 'Latest Report'],
      data: []
    }
  end

  def exposure_closed(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'Eligible for Purge After', 'Reason for Closure',
                'Closed At'],
      data: []
    }
  end

  def exposure_transferred_in(patients)
    {
      columns: ['Monitoree', 'From Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level', 'Monitoring Plan',
                'Transferred At'],
      data: []
    }
  end

  def exposure_transferred_out(patients)
    {
      columns: ['Monitoree', 'To Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level', 'Monitoring Plan',
                'Transferred At'],
      data: []
    }
  end

  def exposure_all(patients)
    puts patients
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'End of Monitoring', 'Risk Level',
                'Monitoring Plan', 'Latest Report', 'Status'],
      data: []
    }
  end

  def isolation_requiring_review(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'Monitoring Plan', 'Latest Report'],
      data: []
    }
  end

  def isolation_non_reporting(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'Monitoring Plan', 'Latest Report'],
      data: []
    }
  end

  def isolation_reporting(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'Monitoring Plan', 'Latest Report'],
      data: []
    }
  end

  def isolation_closed(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'Eligible for Purge After', 'Reason for Closure',
                'Closed At'],
      data: []
    }
  end

  def isolation_transferred_in(patients)
    {
      columns: ['Monitoree', 'From Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth', 'Monitoring Plan', 'Transferred At'],
      data: []
    }
  end

  def isolation_transferred_out(patients)
    {
      columns: ['Monitoree', 'To Jurisdiction', 'State/Local ID', 'Sex', 'Date of Birth', 'Monitoring Plan', 'Transferred At'],
      data: []
    }
  end

  def isolation_all(patients)
    {
      columns: ['Monitoree', 'Jurisdiction', 'Assigned User', 'State/Local ID', 'Sex', 'Date of Birth', 'Monitoring Plan', 'Latest Report', 'Status'],
      data: []
    }
  end
end
