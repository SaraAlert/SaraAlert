# frozen_string_literal: true

# Helper methods for filtering through patients
module PatientFiltersHelper # rubocop:todo Metrics/ModuleLength
  def validate_filter_params(permitted_params)
    # Validate workflow param
    workflow = permitted_params[:workflow].to_sym
    raise InvalidFilterError.new(:workflow, workflow) unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = permitted_params[:tab].to_sym
    if workflow == :exposure
      raise InvalidFilterError.new(:tab, tab) unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      raise InvalidFilterError.new(:tab, tab) unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Validate jurisdiction param
    jurisdiction = permitted_params[:jurisdiction]
    unless jurisdiction.nil? || jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(jurisdiction.to_i)
      raise InvalidFilterError.new(:jurisdiction, jurisdiction)
    end

    # Validate scope param
    scope = permitted_params[:scope]&.to_sym
    raise InvalidFilterError.new(:scope, scope) unless scope.nil? || %i[all exact].include?(scope)

    # Validate user param
    user = permitted_params[:user]
    raise InvalidFilterError.new(:user, user) unless user.nil? || %w[all none].include?(user) || user.to_i.between?(1, 9999)

    # Validate sort params
    order = permitted_params[:order]
    raise InvalidFilterError.new(:order, order) unless order.nil? || order.blank? || %w[name jurisdiction transferred_from transferred_to assigned_user
                                                                                        state_local_id dob end_of_monitoring risk_level monitoring_plan
                                                                                        public_health_action expected_purge_date reason_for_closure closed_at
                                                                                        transferred_at latest_report symptom_onset
                                                                                        extended_isolation].include?(order)

    direction = permitted_params[:direction]
    raise InvalidFilterError.new(:direction, direction) unless direction.nil? || direction.blank? || %w[asc desc].include?(direction)
    raise InvalidFilterError.new(:direction, direction) unless (!order.blank? && !direction.blank?) || (order.blank? && direction.blank?)
  end

  def filtered_patients(permitted_params)
    workflow = permitted_params[:workflow].to_sym
    tab = permitted_params[:tab].to_sym
    jurisdiction = permitted_params[:jurisdiction]
    scope = permitted_params[:scope]&.to_sym
    user = permitted_params[:user]
    search = permitted_params[:search]
    order = permitted_params[:order]
    direction = permitted_params[:direction]

    # Get current user's viewable patients by linelist
    patients = patients_by_linelist(workflow, tab)

    # Filter by assigned jurisdiction
    unless jurisdiction.nil? || jurisdiction == 'all' || tab == :transferred_out
      jur_id = jurisdiction.to_i
      patients = scope == :all ? patients.where(jurisdiction_id: Jurisdiction.find(jur_id).subtree_ids) : patients.where(jurisdiction_id: jur_id)
    end

    # Filter by assigned user
    patients = patients.where(assigned_user: user == 'none' ? nil : user.to_i) unless user.nil? || user == 'all'

    # Filter by search text
    patients = filter_by_text(patients, search)

    # Filter by advanced filter (if present)
    if params[:filter].present?
      advanced = params.require(:filter).collect do |filter|
        {
          filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, options: []),
          value: filter.permit(:value)[:value] || filter.require(:value) || nil,
          dateOption: filter.permit(:dateOption)[:dateOption]
        }
      end
      patients = advanced_filter(patients, advanced) unless advanced.nil?
    end

    # Sort
    sort(patients, order, direction)
  end

  def patients_by_linelist(workflow, tab)
    return current_user.viewable_patients if workflow.nil?
    return current_user.viewable_patients.where(isolation: workflow == :isolation) if !workflow.nil? && tab.nil?

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

  def filter_by_text(patients, search)
    return patients if search.nil? || search.blank?

    patients.where('lower(first_name) like ?', "#{search&.downcase}%").or(
      patients.where('lower(last_name) like ?', "#{search&.downcase}%").or(
        patients.where('lower(user_defined_id_statelocal) like ?', "#{search&.downcase}%").or(
          patients.where('lower(user_defined_id_cdc) like ?', "#{search&.downcase}%").or(
            patients.where('lower(user_defined_id_nndss) like ?', "#{search&.downcase}%").or(
              patients.where('date_of_birth like ?', "#{search&.downcase}%")
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

  # rubocop:disable Metrics/MethodLength
  def advanced_filter(patients, filters)
    filters.each do |filter|
      case filter[:filterOption]['name']
      when 'sent-today'
        patients = if filter[:value].present?
                     patients.where('last_assessment_reminder_sent >= ?', 24.hours.ago)
                   else
                     patients.where('last_assessment_reminder_sent < ?', 24.hours.ago).or(patients.where(last_assessment_reminder_sent: nil))
                   end
      when 'responded-today'
        patients = if filter[:value].present?
                     patients.where('latest_assessment_at >= ?', 24.hours.ago)
                   else
                     patients.where('latest_assessment_at < ?', 24.hours.ago).or(patients.where(latest_assessment_at: nil))
                   end
      when 'paused'
        patients = patients.where(pause_notifications: filter[:value].present? ? true : [nil, false])
      when 'monitoring-status'
        patients = patients.where(monitoring: filter[:value].present? ? true : [nil, false])
      when 'preferred-contact-method'
        patients = patients.where(preferred_contact_method: filter[:value].blank? ? [nil, ''] : filter[:value])
      when 'latest-report'
        case filter[:dateOption]
        when 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(latest_assessment_at) < ?', compare_date)
        when 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(latest_assessment_at) > ?', compare_date)
        when 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('Date(latest_assessment_at) > ?', compare_date_start).where('Date(latest_assessment_at) < ?', compare_date_end)
        end
      when 'hoh'
        patients = if filter[:value]
                     patients.where('patients.id = patients.responder_id')
                   else
                     patients.where.not('patients.id = patients.responder_id')
                   end
      when 'household-member'
        patients = if filter[:value]
                     patients.where.not('patients.id = patients.responder_id')
                   else
                     patients.where('patients.id = patients.responder_id')
                   end
      when 'enrolled'
        case filter[:dateOption]
        when 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(patients.created_at) < ?', compare_date)
        when 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(patients.created_at) > ?', compare_date)
        when 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('Date(patients.created_at) > ?', compare_date_start).where('Date(patients.created_at) < ?', compare_date_end)
        end
      when 'last-date-exposure'
        case filter[:dateOption]
        when 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(last_date_of_exposure) < ?', compare_date)
        when 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(last_date_of_exposure) > ?', compare_date)
        when 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('Date(last_date_of_exposure) > ?', compare_date_start).where('Date(last_date_of_exposure) < ?', compare_date_end)
        end
      when 'symptom-onset'
        case filter[:dateOption]
        when 'before'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(symptom_onset) < ?', compare_date)
        when 'after'
          compare_date = Chronic.parse(filter[:value])
          patients = patients.where('Date(symptom_onset) > ?', compare_date)
        when 'within'
          compare_date_start = Chronic.parse(filter[:value][:start])
          compare_date_end = Chronic.parse(filter[:value][:end])
          patients = patients.where('Date(symptom_onset) > ?', compare_date_start).where('Date(symptom_onset) < ?', compare_date_end)
        end
      when 'continous-exposure'
        patients = patients.where(continuous_exposure: filter[:value].present? ? true : [nil, false])
      when 'telephone-number'
        patients = if filter[:value].blank?
                     patients.where(primary_telephone: [nil, ''])
                   else
                     patients.where('patients.primary_telephone like ?', Phonelib.parse(filter[:value], 'US').full_e164)
                   end
      when 'telephone-number-partial'
        patients = if filter[:value].blank?
                     patients.where(primary_telephone: [nil, ''])
                   else
                     patients.where('patients.primary_telephone like ?', "%#{filter[:value]}%")
                   end
      when 'email'
        patients = if filter[:value].blank?
                     patients.where(email: [nil, ''])
                   else
                     patients.where('lower(patients.email) like ?', "%#{filter[:value]&.downcase}%")
                   end
      when 'primary-language'
        patients = if filter[:value].blank?
                     patients.where(primary_language: [nil, ''])
                   else
                     patients.where('lower(patients.primary_language) like ?', "%#{filter[:value]&.downcase}%")
                   end
      when 'sara-id'
        patients = patients.where(id: filter[:value])
      when 'first-name'
        patients = if filter[:value].blank?
                     patients.where(first_name: [nil, ''])
                   else
                     patients.where('lower(patients.first_name) like ?', "%#{filter[:value]&.downcase}%")
                   end
      when 'middle-name'
        patients = if filter[:value].blank?
                     patients.where(middle_name: [nil, ''])
                   else
                     patients.where('lower(patients.middle_name) like ?', "%#{filter[:value]&.downcase}%")
                   end
      when 'last-name'
        patients = if filter[:value].blank?
                     patients.where(last_name: [nil, ''])
                   else
                     patients.where('lower(patients.last_name) like ?', "%#{filter[:value]&.downcase}%")
                   end
      when 'cohort'
        patients = if filter[:value].blank?
                     patients.where(member_of_a_common_exposure_cohort_type: [nil, ''])
                   else
                     patients.where('lower(patients.member_of_a_common_exposure_cohort_type) like ?', "%#{filter[:value]&.downcase}%")
                   end
      when 'address-usa'
        patients = patients.where('lower(patients.address_line_1) like ?', "%#{filter[:value]&.downcase}%").or(
          patients.where('lower(patients.address_line_2) like ?', "%#{filter[:value]&.downcase}%").or(
            patients.where('lower(patients.address_city) like ?', "%#{filter[:value]&.downcase}%").or(
              patients.where('lower(patients.address_state) like ?', "%#{filter[:value]&.downcase}%").or(
                patients.where('lower(patients.address_zip) like ?', "%#{filter[:value]&.downcase}%").or(
                  patients.where('lower(patients.address_county) like ?', "%#{filter[:value]&.downcase}%")
                )
              )
            )
          )
        )
      when 'address-foreign'
        patients = patients.where('lower(patients.foreign_address_line_1) like ?', "%#{filter[:value]&.downcase}%").or(
          patients.where('lower(patients.foreign_address_line_2) like ?', "%#{filter[:value]&.downcase}%").or(
            patients.where('lower(patients.foreign_address_line_3) like ?', "%#{filter[:value]&.downcase}%").or(
              patients.where('lower(patients.foreign_address_city) like ?', "%#{filter[:value]&.downcase}%").or(
                patients.where('lower(patients.foreign_address_zip) like ?', "%#{filter[:value]&.downcase}%").or(
                  patients.where('lower(patients.foreign_address_state) like ?', "%#{filter[:value]&.downcase}%").or(
                    patients.where('lower(patients.foreign_address_country) like ?', "%#{filter[:value]&.downcase}%")
                  )
                )
              )
            )
          )
        )
      when 'monitoring-plan'
        patients = patients.where(monitoring_plan: filter[:value].blank? ? [nil, ''] : filter[:value])
      when 'never-responded'
        patients = if filter[:value]
                     patients.where(latest_assessment_at: nil)
                   else
                     patients.where.not(latest_assessment_at: nil)
                   end
      when 'risk-exposure'
        patients = patients.where(exposure_risk_assessment: filter[:value].blank? ? [nil, ''] : filter[:value])
      when 'require-interpretation'
        patients = patients.where(interpretation_required: filter[:value].present? ? true : [nil, false])
      when 'preferred-contact-time'
        patients = patients.where(preferred_contact_time: filter[:value].blank? ? [nil, ''] : filter[:value])
      end
    end
    patients
  end
  # rubocop:enable Metrics/MethodLength
end

# Exception used for reporting validation errors
class InvalidFilterError < StandardError
  def initialize(filter, value)
    super("Invalid Filter (#{filter}): #{value}")
  end
end
