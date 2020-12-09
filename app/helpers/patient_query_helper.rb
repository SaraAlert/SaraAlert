# frozen_string_literal: true

# Helper methods for filtering through patients
module PatientQueryHelper # rubocop:todo Metrics/ModuleLength
  RACE_FIELDS = %i[white black_or_african_american american_indian_or_alaska_native asian native_hawaiian_or_other_pacific_islander].freeze

  PATIENT_FIELD_TYPES = {
    numbers: %i[id assigned_user responder_id],
    strings: %i[first_name middle_name last_name sex ethnicity primary_language secondary_language nationality user_defined_id_statelocal user_defined_id_cdc
                user_defined_id_nndss address_line_1 address_city address_state address_line_2 address_zip address_county foreign_address_line_1
                foreign_address_city foreign_address_country foreign_address_line_2 foreign_address_zip foreign_address_line_3 foreign_address_state
                monitored_address_line_1 monitored_address_city monitoring_address_state monitored_address_state monitored_address_line_2 monitored_address_zip
                monitored_address_county foreign_monitored_address_line_1 foreign_monitored_address_city foreign_monitored_address_state
                foreign_monitored_address_line_2 foreign_monitored_address_zip foreign_monitored_address_county preferred_contact_method primary_telephone_type
                secondary_telephone_type preferred_contact_time email port_of_origin source_of_report source_of_report_specify flight_or_vessel_number
                flight_or_vessel_carrier port_of_entry_into_usa travel_related_notes additional_planned_travel_type additional_planned_travel_destination
                additional_planned_travel_destination_state additional_planned_travel_destination_country additional_planned_travel_port_of_departure
                additional_planned_travel_related_notes potential_exposure_location potential_exposure_country contact_of_known_case_id
                was_in_health_care_facility_with_known_cases_facility_name laboratory_personnel_facility_name healthcare_personnel_facility_name
                member_of_a_common_exposure_cohort_type exposure_risk_assessment monitoring_plan exposure_notes case_status gender_identity
                sexual_orientation risk_level monitoring_reason public_health_action],
    dates: %i[date_of_birth date_of_departure date_of_arrival additional_planned_travel_start_date additional_planned_travel_end_date last_date_of_exposure
              symptom_onset extended_isolation last_assessment_reminder_sent latest_assessment_at latest_transfer_at closed_at created_at updated_at],
    booleans: %i[interpretation_required isolation continuous_exposure contact_of_known_case travel_to_affected_country_or_area
                 was_in_health_care_facility_with_known_cases laboratory_personnel healthcare_personnel crew_on_passenger_or_cargo_flight
                 member_of_a_common_exposure_cohort head_of_household pause_notifications].concat(RACE_FIELDS),
    phones: %i[primary_telephone secondary_telephone]
  }.freeze

  PATIENT_STATUS_LABELS = {
    exposure_symptomatic: 'symptomatic',
    exposure_asymptomatic: 'asymptomatic',
    expsoure_non_reporting: 'non-reporting',
    exposure_under_investigation: 'PUI',
    isolation_asymp_non_test_based: 'requires review (asymptomatic non test based)',
    isolation_symp_non_test_based: 'requires review (symptomatic non test based)',
    isolation_test_based: 'requires review (test based)',
    isolation_reporting: 'reporting',
    isolation_non_reporting: 'non-reporting',
    purged: 'purged',
    closed: 'closed'
  }.freeze

  def validate_patients_query(unsanitized_query)
    # Only allow permitted params
    query = unsanitized_query.permit(:workflow, :tab, :jurisdiction, :scope, :user, :search, :entries, :page, :order, :direction, :tz_offset,
                                     filter: [:value, :dateOption, :relativeOption, { filterOption: {}, value: {} }])

    # Validate workflow
    workflow = query[:workflow]&.to_sym || :all
    raise InvalidQueryError.new(:workflow, workflow) unless %i[exposure isolation all].include?(workflow)

    # Validate tab (linelist)
    tab = query[:tab]&.to_sym || :all
    if workflow == :exposure
      raise InvalidQueryError.new(:tab, tab) unless %i[all symptomatic non_reporting asymptomatic pui closed transferred_in transferred_out].include?(tab)
    elsif workflow == :isolation
      raise InvalidQueryError.new(:tab, tab) unless %i[all requiring_review non_reporting reporting closed transferred_in transferred_out].include?(tab)
    else
      raise InvalidQueryError.new(:tab, tab) unless %i[all closed transferred_in transferred_out].include?(tab)
    end

    # Validate jurisdiction
    jurisdiction = query[:jurisdiction]
    unless jurisdiction.nil? || jurisdiction == 'all' || current_user.jurisdiction.subtree_ids.include?(jurisdiction.to_i)
      raise InvalidQueryError.new(:jurisdiction, jurisdiction)
    end

    # Validate jurisdiction scope
    scope = query[:scope]
    raise InvalidQueryError.new(:scope, scope) unless scope.nil? || %w[all exact].include?(scope)

    # Validate assigned user
    user = query[:user]
    raise InvalidQueryError.new(:user, user) unless user.nil? || %w[none].include?(user) || user.to_i.between?(1, 9999)

    # Validate advanced filter (also transform from rails params to array of hashes)
    if unsanitized_query[:filter]
      tz_offset = query.require(:tz_offset)
      raise InvalidQueryError.new(:tz_offset, tz_offset) unless tz_offset.to_i.to_s == tz_offset

      query[:filter] = unsanitized_query[:filter].collect do |filter|
        permitted_filter_params = filter.permit(:value, :dateOption, :relativeOption, filterOption: {}, value: {})
        {
          filterOption: filter.require(:filterOption).permit(:name, :title, :description, :type, options: []),
          value: permitted_filter_params[:value] || filter.require(:value) || false,
          dateOption: permitted_filter_params[:dateOption],
          relativeOption: permitted_filter_params[:relativeOption]
        }
      end
    end

    # Validate sorting order
    order = query[:order]
    raise InvalidQueryError.new(:order, order) unless order.nil? || order.blank? || %w[name jurisdiction transferred_from transferred_to assigned_user
                                                                                       state_local_id dob end_of_monitoring risk_level monitoring_plan
                                                                                       public_health_action expected_purge_date reason_for_closure closed_at
                                                                                       transferred_at latest_report symptom_onset
                                                                                       extended_isolation].include?(order)

    # Validate sorting direction
    direction = query[:direction]
    raise InvalidQueryError.new(:direction, direction) unless direction.nil? || direction.blank? || %w[asc desc].include?(direction)
    raise InvalidQueryError.new(:direction, direction) unless (!order.blank? && !direction.blank?) || (order.blank? && direction.blank?)

    query
  end

  def patients_by_query(current_user, query)
    # Determine jurisdiction
    jurisdiction = Jurisdiction.find(query[:jurisdiction].to_i) unless ['all', nil].include?(query[:jurisdiction])
    jurisdiction = current_user.jurisdiction if jurisdiction.nil?

    # Get current user's viewable patients by linelist
    patients = patients_by_linelist(current_user, query[:workflow]&.to_sym, query[:tab]&.to_sym, jurisdiction)

    # Filter by assigned jurisdiction
    patients = patients.where(jurisdiction_id: jurisdiction.subtree_ids) if jurisdiction != current_user.jurisdiction && query[:tab] != :transferred_out

    # Fitler by scope
    patients = patients.where(jurisdiction_id: jurisdiction.id) if query[:scope] == 'exact' && query[:tab] != :transferred_out

    # Filter by assigned user
    patients = patients.where(assigned_user: query[:user] == 'none' ? nil : query[:user].to_i) unless query[:user].nil?

    # Filter by search text
    patients = filter_by_text(patients, query[:search])

    # Filter by advanced filter
    patients = advanced_filter(patients, query[:filter], query[:tz_offset])

    # Sort
    sort(patients, query[:order], query[:direction])
  end

  def patients_by_linelist(current_user, workflow, tab, jurisdiction)
    case workflow
    when :exposure
      return current_user.viewable_patients.exposure_symptomatic if tab == :symptomatic
      return current_user.viewable_patients.exposure_non_reporting if tab == :non_reporting
      return current_user.viewable_patients.exposure_asymptomatic if tab == :asymptomatic
      return current_user.viewable_patients.exposure_under_investigation if tab == :pui
      return current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: false) if tab == :closed
      return jurisdiction.transferred_in_patients.monitoring_open.where(isolation: false) if tab == :transferred_in
      return jurisdiction.transferred_out_patients.monitoring_open.where(isolation: false) if tab == :transferred_out

      current_user.viewable_patients.where(isolation: false, purged: false)
    when :isolation
      return current_user.viewable_patients.isolation_requiring_review if tab == :requiring_review
      return current_user.viewable_patients.isolation_non_reporting if tab == :non_reporting
      return current_user.viewable_patients.isolation_reporting if tab == :reporting
      return current_user.viewable_patients.monitoring_closed_without_purged.where(isolation: true) if tab == :closed
      return jurisdiction.transferred_in_patients.monitoring_open.where(isolation: true) if tab == :transferred_in
      return jurisdiction.transferred_out_patients.monitoring_open.where(isolation: true) if tab == :transferred_out

      current_user.viewable_patients.where(isolation: true, purged: false)
    else
      return current_user.viewable_patients.monitoring_closed_without_purged if tab == :closed
      return jurisdiction.transferred_in_patients.monitoring_open if tab == :transferred_in
      return jurisdiction.transferred_out_patients.monitoring_open if tab == :transferred_out

      current_user.viewable_patients.where(purged: false)
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
    return patients unless filters.present?

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

  def extract_patients_details(patients_group, fields)
    # perform the following queries in bulk only if requested for better performance
    patients_jurisdiction_names = jurisdiction_names(patients_group) if fields.include?(:jurisdiction_name)
    patients_jurisdiction_paths = jurisdiction_paths(patients_group) if fields.include?(:jurisdiction_path)
    patients_transfers = transfers(patients_group) if (fields & %i[transferred_from transferred_to]).any?
    lab_fields = %i[lab_1_type lab_1_specimen_collection lab_1_report lab_1_result lab_2_type lab_2_specimen_collection lab_2_report lab_2_result]
    patients_labs = laboratories(patients_group) if (fields & lab_fields).any?
    patients_creators = Hash[User.find(patients_group.pluck(:creator_id)).pluck(:id, :email)] if fields.include?(:creator)

    # construct patient details
    patients_details = []
    patients_group.each do |patient|
      # populate requested inherent fields
      patient_details = extract_incomplete_patient_details(patient, fields)

      # populate creator if requested
      patient_details[:creator] = patients_creators[patient.creator_id] || '' if fields.include?(:creator)

      # populate jurisdiction if requested
      patient_details[:jurisdiction_name] = patients_jurisdiction_names[patient.id] || '' if fields.include?(:jurisdiction_name)
      patient_details[:jurisdiction_path] = patients_jurisdiction_paths[patient.id] || '' if fields.include?(:jurisdiction_path)

      # populate latest transfer from and to if requested
      if patients_transfers&.key?(patient.id)
        patient_details[:transferred_from] = patients_transfers[patient.id][:trasnferred_from] if fields.include?(:transferred_from)
        patient_details[:transferred_to] = patients_transfers[patient.id][:transferred_to] if fields.include?(:transferred_to)
      end

      # populate labs if requested
      if patients_labs&.key?(patient.id)
        if patients_labs[patient.id].key?(:first)
          patient_details[:lab_1_type] = patients_labs[patient.id][:first][:lab_type] || '' if fields.include?(:lab_1_type)
          if fields.include?(:lab_1_specimen_collection)
            patient_details[:lab_1_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_1_report] = patients_labs[patient.id][:first][:report]&.strftime('%F') || '' if fields.include?(:lab_1_report)
          patient_details[:lab_1_result] = patients_labs[patient.id][:first][:result] || '' if fields.include?(:lab_1_result)
        end
        if patients_labs[patient.id].key?(:second)
          patient_details[:lab_2_type] = patients_labs[patient.id][:first][:lab_type] || '' if fields.include?(:lab_2_type)
          if fields.include?(:lab_2_specimen_collection)
            patient_details[:lab_2_specimen_collection] = patients_labs[patient.id][:first][:specimen_collection]&.strftime('%F') || ''
          end
          patient_details[:lab_2_report] = patients_labs[patient.id][:first][:report]&.strftime('%F') || '' if fields.include?(:lab_2_report)
          patient_details[:lab_2_result] = patients_labs[patient.id][:first][:result] || '' if fields.include?(:lab_2_result)
        end
      end

      patients_details << patient_details
    end

    patients_details
  end

  def extract_incomplete_patient_details(patient, fields)
    patient_details = {}

    (PATIENT_FIELD_TYPES[:numbers] + PATIENT_FIELD_TYPES[:strings]).each do |field|
      patient_details[field] = patient[field] || '' if fields.include?(field)
    end

    PATIENT_FIELD_TYPES[:dates].each do |field|
      patient_details[field] = patient[field]&.strftime('%F') || '' if fields.include?(field)
    end

    PATIENT_FIELD_TYPES[:booleans].each do |field|
      patient_details[field] = patient[field] || false if fields.include?(field)
    end

    PATIENT_FIELD_TYPES[:phones].each do |field|
      patient_details[field] = format_phone_number(patient[field]) if fields.include?(field)
    end

    RACE_FIELDS.each { |race| patient_details[race] = patient[race] || false } if fields.include?(:race)

    patient_details[:name] = patient.displayed_name if fields.include?(:name)
    patient_details[:age] = patient.calc_current_age if fields.include?(:age)
    patient_details[:workflow] = patient[:isolation] ? 'Isolation' : 'Workflow'
    patient_details[:symptom_onset_defined_by] = patient[:user_defined_symptom_onset] ? 'User' : 'System'
    patient_details[:monitoring_status] = patient[:monitoring] ? 'Actively Monitoring' : 'Not Monitoring'
    patient_details[:end_of_monitoring] = patient.end_of_monitoring || '' if fields.include?(:end_of_monitoring)
    patient_details[:expected_purge_date] = patient.expected_purge_date || '' if fields.include?(:expected_purge_date)
    patient_details[:status] = PATIENT_STATUS_LABELS[patient.status] || '' if fields.include?(:status)

    patient_details
  end
end

# Exception used for reporting validation errors
class InvalidQueryError < StandardError
  def initialize(field, value)
    super("Invalid Query (#{field}): #{value}")
  end
end
