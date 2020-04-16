# frozen_string_literal: true

# Patient: patient model
class Patient < ApplicationRecord
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  validates :monitoring_reason, inclusion: { in: ['Completed Monitoring',
                                                  'Lost to follow-up during monitoring period',
                                                  'Lost to follow-up (contact never established)',
                                                  'Transferred to another jurisdiction',
                                                  'Person Under Investigation (PUI)',
                                                  'Case confirmed',
                                                  'Past monitoring period',
                                                  'Meets criteria to discontinue isolation',
                                                  'Deceased',
                                                  'Other',
                                                  nil, ''] }

  validates :monitoring_plan, inclusion: { in: ['None',
                                                'Daily active monitoring',
                                                'Self-monitoring with public health supervision',
                                                'Self-monitoring with delegated supervision',
                                                'Self-observation',
                                                nil, ''] }

  validates :exposure_risk_assessment, inclusion: { in: ['High',
                                                         'Medium',
                                                         'Low',
                                                         'No Identified Risk',
                                                         nil, ''] }

  validates :public_health_action, inclusion: { in: ['None',
                                                     'Recommended medical evaluation of symptoms',
                                                     'Document results of medical evaluation',
                                                     'Laboratory specimen collected',
                                                     'Recommended laboratory testing',
                                                     'Laboratory received specimen – result pending',
                                                     'Laboratory report results – positive',
                                                     'Laboratory report results – negative',
                                                     'Laboratory report results – indeterminate',
                                                     nil, ''] }

  belongs_to :responder, class_name: 'Patient'
  belongs_to :creator, class_name: 'User'
  has_many :dependents, class_name: 'Patient', foreign_key: 'responder_id'
  has_many :assessments
  has_one :latest_assessment, -> { order created_at: :desc }, class_name: 'Assessment'
  belongs_to :jurisdiction
  has_many :histories
  has_many :transfers
  has_one :latest_transfer, -> { order(created_at: :desc) }, class_name: 'Transfer'

  # All individuals currently being monitored
  scope :monitoring_open, lambda {
    where('monitoring = ?', true)
      .where('purged = ?', false)
  }

  # All individuals currently not being monitored
  scope :monitoring_closed, lambda {
    where('monitoring = ?', false)
  }

  # All individuals that have been closed (not including purged)
  scope :monitoring_closed_without_purged, lambda {
    where('monitoring = ?', false)
      .where('purged = ?', false)
  }

  # All individuals that have been closed (including purged)
  scope :monitoring_closed_with_purged, lambda {
    where('monitoring = ?', false)
      .where('purged = ?', true)
  }

  # Purgeable records
  scope :purgeable, lambda {
    where('monitoring = ?', false)
      .where('purged = ?', false)
      .where('updated_at < ?', ADMIN_OPTIONS['purgeable_after'].minutes.ago)
  }

  # Purged monitoree records
  scope :purged, lambda {
    where('purged = ?', true)
  }

  # All individuals who are confirmed cases
  scope :confirmed_case, lambda {
    where('monitoring_reason = ?', 'Case confirmed')
  }

  # Any individual who is currently under investigation
  scope :under_investigation, lambda {
    where('monitoring = ?', true)
      .where('purged = ?', false)
      .where.not('public_health_action = ?', 'None')
      .where(isolation: false)
  }

  # Any individual who has any assessments still considered symptomatic
  scope :symptomatic, lambda {
    where('monitoring = ?', true)
      .where('purged = ?', false)
      .left_outer_joins(:assessments)
      .where('assessments.patient_id = patients.id')
      .where('assessments.symptomatic = ?', true)
      .where('public_health_action = ?', 'None')
      .distinct
  }

  # Non reporting asymptomatic individuals
  scope :non_reporting, lambda {
    where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .where('monitoring = ?', true)
      .where('purged = ?', false)
      .where('public_health_action = ?', 'None')
      .left_outer_joins(:assessments)
      .where('assessments.patient_id = patients.id')
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .where_assoc_not_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
      .or(
        where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
        .where('monitoring = ?', true)
        .where('purged = ?', false)
        .where('public_health_action = ?', 'None')
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
      )
      .distinct
  }

  # Individuals who have reported recently and are not symptomatic
  scope :asymptomatic, lambda {
    where('monitoring = ?', true)
      .where('purged = ?', false)
      .where('public_health_action = ?', 'None')
      .left_outer_joins(:assessments)
      .where('assessments.patient_id = patients.id')
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .where_assoc_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
      .or(
        where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
        .where('monitoring = ?', true)
        .where('purged = ?', false)
        .where('public_health_action = ?', 'None')
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
      )
      .distinct
  }

  scope :isolation_requiring_review, lambda {
    where('monitoring = ?', true)
      .where('purged = ?', false)
      .where('isolation = ?', true)
      .where_assoc_exists(:assessments, &:seventy_two_hours_since_latest_fever_report)
      .where_assoc_exists(:assessments, ['created_at >= ?', 24.hours.ago])
      .distinct
      .or(
        where('monitoring = ?', true)
        .where('purged = ?', false)
        .where('isolation = ?', true)
        .where_assoc_count(2, :<=, :histories, 'comment LIKE \'%Laboratory report results – negative%\'')
        .where_assoc_exists(:assessments, &:twenty_four_hours_since_latest_fever_report)
        .where_assoc_exists(:assessments, ['created_at >= ?', 24.hours.ago])
        .distinct
      )
  }

  scope :isolation_non_reporting, lambda {
    where('monitoring = ?', true)
      .where('purged = ?', false)
      .where('isolation = ?', true)
      .where_assoc_not_exists(:assessments, ['created_at >= ?', 24.hours.ago])
      .distinct
  }

  scope :isolation_reporting, lambda {
    where('monitoring = ?', true)
      .where('purged = ?', false)
      .where('isolation = ?', true)
      .where_assoc_exists(:assessments, ['created_at >= ?', 24.hours.ago])
      .where.not(id: Patient.unscoped.isolation_requiring_review)
  }

  # All individuals currently being monitored if true, all individuals otherwise
  scope :monitoring_active, lambda { |active_monitoring|
    where(monitoring: true) if active_monitoring
  }

  # All individuals with the given monitoring status
  scope :monitoring_status, lambda { |monitoring_status|
    case monitoring_status
    when 'Symptomatic'
      symptomatic
    when 'Non-Reporting'
      non_reporting
    when 'Asymptomatic'
      asymptomatic
    end
  }

  # All individuals with a last date of exposure within the given time frame
  scope :exposed_in_time_frame, lambda { |time_frame|
    where('last_date_of_exposure >= ?', time_frame)
  }

  # All individuals enrolled within the given time frame
  scope :enrolled_in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('patients.created_at >= ?', 24.hours.ago)
    when 'Last 14 Days'
      where('patients.created_at >= ? AND patients.created_at < ?', 14.days.ago.to_date.to_datetime, Date.today.to_datetime)
    end
  }

  # Order individuals based on their public health assigned risk assessment
  def self.order_by_risk(asc = true)
    order_by = ["WHEN exposure_risk_assessment='High' THEN 0",
                "WHEN exposure_risk_assessment='Medium' THEN 1",
                "WHEN exposure_risk_assessment='Low' THEN 2",
                "WHEN exposure_risk_assessment='No Identified Risk' THEN 3",
                'WHEN exposure_risk_assessment IS NULL THEN 4']
    order_by_rev = ['WHEN exposure_risk_assessment IS NULL THEN 4',
                    "WHEN exposure_risk_assessment='High' THEN 3",
                    "WHEN exposure_risk_assessment='Medium' THEN 2",
                    "WHEN exposure_risk_assessment='Low' THEN 1",
                    "WHEN exposure_risk_assessment='No Identified Risk' THEN 0"]
    order((['CASE'] + (asc ? order_by : order_by_rev) + ['END']).join(' '))
  end

  # Check for potential matches based on first and last name, sex, and date of birth
  def self.matches(first_name, last_name, sex, date_of_birth)
    where('lower(first_name) = ?', first_name&.downcase)
      .where('lower(last_name) = ?', last_name&.downcase)
      .where('lower(sex) = ?', sex&.downcase)
      .where('date_of_birth = ?', date_of_birth)
  end

  # True if this person is responsible for reporting
  def self_reporter_or_proxy?
    responder_id == id
  end

  # Allow information on the monitoree's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    return last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days if last_date_of_exposure
    return created_at + ADMIN_OPTIONS['monitoring_period_days'].days if created_at
  end

  # Is this patient symptomatic?
  def symptomatic?
    assessments.where(symptomatic: true).count.positive?
  end

  # Is this patient symptomatic?
  def asymptomatic?
    (!latest_assessment.nil? &&
     assessments.where(symptomatic: true).count.zero? &&
     latest_assessment.created_at >= ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago) ||
      (created_at && latest_assessment.nil? &&
       created_at >= ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
  end

  # Is this patient non_reporting?
  def non_reporting?
    (!latest_assessment.nil? &&
     assessments.where(symptomatic: true).count.zero? &&
     latest_assessment.created_at < ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago) ||
      (latest_assessment.nil? && created_at && created_at < ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
  end

  # Is this patient under investigation?
  def pui?
    monitoring && !purged && public_health_action != 'None'
  end

  # Has this patient purged?
  def purged?
    purged
  end

  # Has this patient purged?
  def closed?
    !monitoring && !purged
  end

  # Current patient status
  def status
    unless isolation
      return :pui if pui?
      return :purged if purged?
      return :closed if closed?
      return :symptomatic if symptomatic?
      return :asymptomatic if asymptomatic?
      return :non_reporting if non_reporting?
    end
    return :isolation_requiring_review if Patient.isolation_requiring_review.where(id: id).count.positive?
    return :isolation_non_reporting if Patient.isolation_non_reporting.where(id: id).count.positive?
    return :isolation_reporting if Patient.isolation_reporting.where(id: id).count.positive?
    return :purged if purged?
    return :closed if closed?

    :unknown
  end

  # Information about this subject (that is useful in a linelist)
  def linelist
    {
      name: { name: "#{last_name}#{first_name.blank? ? '' : ', ' + first_name}", id: id },
      jurisdiction: jurisdiction&.name || '',
      state_local_id: user_defined_id_statelocal || '',
      sex: sex || '',
      dob: date_of_birth&.strftime('%F') || '',
      end_of_monitoring: end_of_monitoring&.strftime('%F') || '',
      risk_level: exposure_risk_assessment || '',
      monitoring_plan: monitoring_plan || '',
      latest_report: latest_assessment&.created_at&.strftime('%F') || '',
      transferred: latest_transfer&.created_at&.to_s || '',
      reason_for_closure: monitoring_reason || '',
      public_health_action: public_health_action || '',
      status: status&.to_s&.humanize&.downcase || '',
      closed_at: closed_at&.to_s || '',
      transferred_from: latest_transfer&.from_path || '',
      transferred_to: latest_transfer&.to_path || ''
    }
  end

  # All information about this subject
  def comprehensive_details
    {
      first_name: first_name || '',
      middle_name: middle_name || '',
      last_name: last_name || '',
      date_of_birth: date_of_birth&.strftime('%F') || '',
      sex: sex || '',
      white: white || false,
      black_or_african_american: black_or_african_american || false,
      american_indian_or_alaska_native: american_indian_or_alaska_native || false,
      asian: asian || false,
      native_hawaiian_or_other_pacific_islander: native_hawaiian_or_other_pacific_islander || false,
      ethnicity: ethnicity || '',
      primary_language: primary_language || '',
      secondary_language: secondary_language || '',
      interpretation_required: interpretation_required || false,
      nationality: nationality || '',
      user_defined_id_statelocal: user_defined_id_statelocal || '',
      user_defined_id_cdc: user_defined_id_cdc || '',
      user_defined_id_nndss: user_defined_id_nndss || '',
      address_line_1: address_line_1 || '',
      address_city: address_city || '',
      address_state: address_state || '',
      address_line_2: address_line_2 || '',
      address_zip: address_zip || '',
      address_county: address_county || '',
      foreign_address_line_1: foreign_address_line_1 || '',
      foreign_address_city: foreign_address_city || '',
      foreign_address_country: foreign_address_country || '',
      foreign_address_line_2: foreign_address_line_2 || '',
      foreign_address_zip: foreign_address_zip || '',
      foreign_address_line_3: foreign_address_line_3 || '',
      foreign_address_state: foreign_address_state || '',
      monitored_address_line_1: monitored_address_line_1 || '',
      monitored_address_city: monitored_address_city || '',
      monitored_address_state: monitored_address_state || '',
      monitored_address_line_2: monitored_address_line_2 || '',
      monitored_address_zip: monitored_address_zip || '',
      monitored_address_county: monitored_address_county || '',
      foreign_monitored_address_line_1: foreign_monitored_address_line_1 || '',
      foreign_monitored_address_city: foreign_monitored_address_city || '',
      foreign_monitored_address_state: foreign_monitored_address_state || '',
      foreign_monitored_address_line_2: foreign_monitored_address_line_2 || '',
      foreign_monitored_address_zip: foreign_monitored_address_zip || '',
      foreign_monitored_address_county: foreign_monitored_address_county || '',
      preferred_contact_method: preferred_contact_method || '',
      primary_telephone: primary_telephone || '',
      primary_telephone_type: primary_telephone_type || '',
      secondary_telephone: secondary_telephone || '',
      secondary_telephone_type: secondary_telephone_type || '',
      preferred_contact_time: preferred_contact_time || '',
      email: email || '',
      port_of_origin: port_of_origin || '',
      date_of_departure: date_of_departure&.strftime('%F') || '',
      source_of_report: source_of_report || '',
      flight_or_vessel_number: flight_or_vessel_number || '',
      flight_or_vessel_carrier: flight_or_vessel_carrier || '',
      port_of_entry_into_usa: port_of_entry_into_usa || '',
      date_of_arrival: date_of_arrival&.strftime('%F') || '',
      travel_related_notes: travel_related_notes || '',
      additional_planned_travel_type: additional_planned_travel_type || '',
      additional_planned_travel_destination: additional_planned_travel_destination || '',
      additional_planned_travel_destination_state: additional_planned_travel_destination_state || '',
      additional_planned_travel_destination_country: additional_planned_travel_destination_country || '',
      additional_planned_travel_port_of_departure: additional_planned_travel_port_of_departure || '',
      additional_planned_travel_start_date: additional_planned_travel_start_date&.strftime('%F') || '',
      additional_planned_travel_end_date: additional_planned_travel_end_date&.strftime('%F') || '',
      additional_planned_travel_related_notes: additional_planned_travel_related_notes || '',
      last_date_of_exposure: last_date_of_exposure&.strftime('%F') || '',
      potential_exposure_location: potential_exposure_location || '',
      potential_exposure_country: potential_exposure_country || '',
      contact_of_known_case: contact_of_known_case || '',
      contact_of_known_case_id: contact_of_known_case_id || '',
      travel_to_affected_country_or_area: travel_to_affected_country_or_area || false,
      was_in_health_care_facility_with_known_cases: was_in_health_care_facility_with_known_cases || false,
      was_in_health_care_facility_with_known_cases_facility_name: was_in_health_care_facility_with_known_cases_facility_name || '',
      laboratory_personnel: laboratory_personnel || false,
      laboratory_personnel_facility_name: laboratory_personnel_facility_name || '',
      healthcare_personnel: healthcare_personnel || false,
      healthcare_personnel_facility_name: healthcare_personnel_facility_name || '',
      crew_on_passenger_or_cargo_flight: crew_on_passenger_or_cargo_flight || false,
      member_of_a_common_exposure_cohort: member_of_a_common_exposure_cohort || false,
      member_of_a_common_exposure_cohort_type: member_of_a_common_exposure_cohort_type || '',
      exposure_risk_assessment: exposure_risk_assessment || '',
      monitoring_plan: monitoring_plan || '',
      exposure_notes: exposure_notes || '',
      status: status&.to_s&.humanize&.downcase || ''
    }
  end

  # Override as_json to include linelist
  def as_json(options = {})
    super((options || {}).merge(methods: :linelist))
  end

  def send_assessment(force = false)
    unless last_assessment_reminder_sent.nil?
      return if last_assessment_reminder_sent > 20.hours.ago
    end

    # Do not allow messages to go to household members
    return unless responder.id == id

    # If force is set, the preferred contact time will be ignored
    unless force
      hour = Time.now.hour
      if !address_state.blank? && address_state == 'Northern Mariana Islands'
        # CNMI Local
        hour = Time.now.getlocal('+10:00').hour
      end
      if !address_state.blank? && address_state == 'Arkansas'
        # Arkansas Local
        hour = Time.now.getlocal('-05:00').hour
      end
      # These are the hours that we consider to be morning, afternoon and evening
      morning = (8..12)
      afternoon = (12..16)
      evening = (16..20)
      if preferred_contact_time == 'Morning'
        return unless morning.include? hour
      elsif preferred_contact_time == 'Afternoon'
        return unless afternoon.include? hour
      elsif preferred_contact_time == 'Evening'
        return unless evening.include? hour
      end
    end

    if preferred_contact_method == 'SMS Text-message' && responder.id == id && ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
      # SMS-based assessments assess the patient _and_ all of their dependents
      # If you are a dependent ie: someone whose responder.id is not your own an assessment will not be sent to you
      # Because Twilio will open a second SMS flow for this user and send two responses, this option cannot be forced
      # TODO: Find a way to end existing flows/sessions with this patient, and then this option can be forced
      if !force
        PatientMailer.assessment_sms(self).deliver_later
      else
        PatientMailer.assessment_sms_reminder(self).deliver_later
      end
    elsif preferred_contact_method == 'SMS Texted Weblink' && responder.id == id
      PatientMailer.assessment_sms_weblink(self).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
    elsif preferred_contact_method == 'Telephone call' && responder.id == id
      PatientMailer.assessment_voice(self).deliver_later if ADMIN_OPTIONS['enable_voice'] && !Rails.env.test?
    elsif ADMIN_OPTIONS['enable_email'] && responder.id == id
      PatientMailer.assessment_email(self).deliver_later
    end

    update(last_assessment_reminder_sent: DateTime.now)
  end
end
