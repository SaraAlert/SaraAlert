# frozen_string_literal: true

# Helper methods for filtering through patients
module PatientFiltersHelper # rubocop:todo Metrics/ModuleLength
  def validate_filter_params(params)
    # Validate workflow param
    workflow = params[:workflow].to_sym
    raise InvalidFilterError.new(:workflow, workflow) unless %i[exposure isolation].include?(workflow)

    # Validate tab param
    tab = params[:tab].to_sym
    if workflow == :exposure
      raise InvalidFilterError.new(:tab, tab) unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    else
      raise InvalidFilterError.new(:tab, tab) unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    end

    # Validate jurisdiction param
    jurisdiction = params[:jurisdiction]
    unless jurisdiction.nil? || jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(jurisdiction.to_i)
      raise InvalidFilterError.new(:jurisdiction, jurisdiction)
    end

    # Validate scope param
    scope = params[:scope]&.to_sym
    raise InvalidFilterError.new(:scope, scope) unless scope.nil? || %i[all exact].include?(scope)

    # Validate user param
    user = params[:user]
    raise InvalidFilterError.new(:user, user) unless user.nil? || %w[all none].include?(user) || user.to_i.between?(1, 9999)

    # Validate sort params
    order = params[:order]
    raise InvalidFilterError.new(:order, order) unless order.nil? || order.blank? || %w[name jurisdiction transferred_from transferred_to assigned_user
                                                                                        state_local_id dob end_of_monitoring risk_level monitoring_plan
                                                                                        public_health_action expected_purge_date reason_for_closure closed_at
                                                                                        transferred_at latest_report symptom_onset
                                                                                        extended_isolation].include?(order)

    direction = params[:direction]
    raise InvalidFilterError.new(:direction, direction) unless direction.nil? || direction.blank? || %w[asc desc].include?(direction)
    raise InvalidFilterError.new(:direction, direction) unless (!order.blank? && !direction.blank?) || (order.blank? && direction.blank?)

    params.permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :order, :direction, :filter)
  end

  def filtered_patients(current_user, filters)
    workflow = filters[:workflow].to_sym
    tab = filters[:tab].to_sym
    jurisdiction = filters[:jurisdiction]
    scope = filters[:scope]&.to_sym
    user = filters[:user]
    search = filters[:search]
    order = filters[:order]
    direction = filters[:direction]

    # Get current user's viewable patients by linelist
    patients = patients_by_linelist(current_user, workflow, tab)

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
      tz_offset = permitted_params.require(:tz_offset)
      advanced = params.require(:filter).collect do |filter|
        {
          filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, options: []),
          value: filter.permit(:value)[:value] || filter.require(:value) || false,
          dateOption: filter.permit(:dateOption)[:dateOption],
          relativeOption: filter.permit(:relativeOption)[:relativeOption]
        }
      end
      patients = advanced_filter(patients, advanced, tz_offset) unless advanced.nil?
    end

    # Sort
    sort(patients, order, direction)
  end

  def patients_by_linelist(current_user, workflow, tab)
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
      patients = patients.order('CASE WHEN continuous_exposure = 1 THEN 1 ELSE 0 END,
                                 CASE WHEN last_date_of_exposure IS NULL THEN patients.created_at ELSE last_date_of_exposure END ' + dir)
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
      patients = patients.order('CASE WHEN closed_at IS NULL THEN 1 ELSE 0 END, updated_at ' + dir)
      # Eligible purge date is a derivative field from `updated_at`
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
  def advanced_filter(patients, filters, tz_offset)
    # Adjust for difference between client and server timezones.
    # NOTE: Adding server timezone offset in cases where the server may not be running in UTC time.
    # NOTE: + because js and ruby offsets are flipped. Both of these values are in seconds.
    tz_diff = tz_offset.to_i.minutes + DateTime.now.utc_offset

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
        patients = advanced_filter_date(patients, :created_at, filter, tz_diff, :time)
      when 'enrolled-relative'
        patients = advanced_filter_relative_date(patients, :created_at, filter, tz_diff, :time)
      when 'latest-report'
        patients = advanced_filter_date(patients, :latest_assessment_at, filter, tz_diff, :time)
      when 'latest-report-relative'
        patients = advanced_filter_relative_date(patients, :latest_assessment_at, filter, tz_diff, :time)
      when 'last-date-exposure'
        patients = advanced_filter_date(patients, :last_date_of_exposure, filter, tz_diff, :date)
      when 'last-date-exposure-relative'
        patients = advanced_filter_relative_date(patients, :last_date_of_exposure, filter, tz_diff, :date)
      when 'symptom-onset'
        patients = advanced_filter_date(patients, :symptom_onset, filter, tz_diff, :date)
      when 'symptom-onset-relative'
        patients = advanced_filter_relative_date(patients, :symptom_onset, filter, tz_diff, :date)
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
      when 'manual-contact-attempts'
        # less/greater-than operators are flipped for where_assoc_count
        operator = :==
        operator = :> if filter[:value][:operator] == 'less-than'
        operator = :>= if filter[:value][:operator] == 'less-than-equal'
        operator = :<= if filter[:value][:operator] == 'greater-than-equal'
        operator = :< if filter[:value][:operator] == 'greater-than'
        case filter[:value][:option]
        when 'Successful'
          patients = patients.where_assoc_count(filter[:value][:number], operator, :contact_attempts, successful: true)
        when 'Unsuccessful'
          patients = patients.where_assoc_count(filter[:value][:number], operator, :contact_attempts, successful: false)
        when 'All'
          patients = patients.where_assoc_count(filter[:value][:number], operator, :contact_attempts)
        end
      when 'ten-day-quarantine'
        patients = advanced_filter_quarantine_option(patients, filter, tz_offset, :ten_day)
      when 'seven-day-quarantine'
        patients = advanced_filter_quarantine_option(patients, filter, tz_offset, :seven_day)
      end
    end
    patients
  end
  # rubocop:enable Metrics/MethodLength

  # Handles a given quarantine option from the advanced filter.
  def advanced_filter_quarantine_option(patients, filter, tz_offset, option_type)
    # Adjust for difference between client and server timezones.
    # NOTE: Adding server timezone offset in cases where the server may not be running in UTC time.
    # NOTE: + because js and ruby offsets are flipped. Both of these values are in seconds.
    tz_diff = tz_offset.to_i.minutes + DateTime.now.utc_offset
    user_curr_datetime = DateTime.now - tz_diff

    # Get all patients who meet this criteria based on the option type
    case option_type
    when :ten_day
      query = patients.ten_day_quarantine_candidates(user_curr_datetime)
    when :seven_day
      query = patients.seven_day_quarantine_candidates(user_curr_datetime)
    end

    # Based on if the user selected true/false, return appropriate patients
    filter[:value].present? ? query : patients.where.not(id: query.pluck(:id))
  end

  # Filter patients by a set time range for the given field
  def advanced_filter_date(patients, field, filter, tz_diff, type)
    timeframe = { after: Chronic.parse(filter[:value]).beginning_of_day + 1.day } if filter[:dateOption] == 'after'
    timeframe = { before: Chronic.parse(filter[:value]).end_of_day - 1.day } if filter[:dateOption] == 'before'
    if filter[:dateOption] == 'within'
      timeframe = { after: Chronic.parse(filter[:value][:start]).beginning_of_day, before: Chronic.parse(filter[:value][:end]).end_of_day }
    end

    patients_by_field_timeframe(patients, field, timeframe, tz_diff, type)
  end

  # Filter patients by a relative time range for the given field
  def advanced_filter_relative_date(patients, field, filter, tz_diff, type)
    local_current_time = DateTime.now - tz_diff
    timeframe = { after: local_current_time.beginning_of_day, before: local_current_time.end_of_day } if filter[:relativeOption] == 'today'
    timeframe = { after: local_current_time.beginning_of_day + 1.day, before: local_current_time.end_of_day + 1.day } if filter[:relativeOption] == 'tomorrow'
    timeframe = { after: local_current_time.beginning_of_day - 1.day, before: local_current_time.end_of_day - 1.day } if filter[:relativeOption] == 'yesterday'
    if filter[:relativeOption] == 'custom'
      timespan = filter[:value][:number].to_i.days if filter[:value][:unit] == 'days'
      timespan = filter[:value][:number].to_i.weeks if filter[:value][:unit] == 'weeks'
      timespan = filter[:value][:number].to_i.months if filter[:value][:unit] == 'months'
      return patients if timespan.nil?

      timeframe = { after: (timespan.ago - tz_diff).beginning_of_day, before: local_current_time } if filter[:value][:when] == 'past'
      timeframe = { after: local_current_time, before: (timespan.from_now - tz_diff).end_of_day } if filter[:value][:when] == 'next'
    end
    return patients if timeframe.nil?

    patients_by_field_timeframe(patients, field, timeframe, tz_diff, type)
  end

  def patients_by_field_timeframe(patients, field, timeframe, tz_diff, type)
    if timeframe[:after].present?
      # Convert timeframe value to date if field is a date, apply timezone difference if field is a datetime
      after = type == :date ? timeframe[:after].to_date : timeframe[:after] + tz_diff
      patients = patients.where('patients.created_at >= ?', after) if field == :created_at
      patients = patients.where('latest_assessment_at >= ?', after) if field == :latest_assessment_at
      patients = patients.where('last_date_of_exposure >= ?', after) if field == :last_date_of_exposure
      patients = patients.where('symptom_onset >= ?', after) if field == :symptom_onset
    end

    if timeframe[:before].present?
      # Convert timeframe value to date if field is a date, apply timezone difference if field is a datetime
      before = type == :date ? timeframe[:before].to_date : timeframe[:before] + tz_diff
      patients = patients.where('patients.created_at <= ?', before) if field == :created_at
      patients = patients.where('latest_assessment_at <= ?', before) if field == :latest_assessment_at
      patients = patients.where('last_date_of_exposure <= ?', before) if field == :last_date_of_exposure
      patients = patients.where('symptom_onset <= ?', before) if field == :symptom_onset
    end

    patients
  end
end

# Exception used for reporting validation errors
class InvalidFilterError < StandardError
  def initialize(filter, value)
    super("Invalid Filter (#{filter}): #{value}")
  end
end
