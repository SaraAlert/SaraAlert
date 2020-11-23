# frozen_string_literal: true

require 'chronic'

# Patient: patient model
class Patient < ApplicationRecord
  include PatientHelper
  include PatientDetailsHelper
  include ValidationHelper
  include ActiveModel::Validations

  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  validates :monitoring_reason, inclusion: { in: ['Completed Monitoring',
                                                  'Enrolled more than 14 days after last date of exposure (system)',
                                                  'Enrolled on last day of monitoring period (system)',
                                                  'Completed Monitoring (system)',
                                                  'Meets Case Definition',
                                                  'Lost to follow-up during monitoring period',
                                                  'Lost to follow-up (contact never established)',
                                                  'Transferred to another jurisdiction',
                                                  'Person Under Investigation (PUI)',
                                                  'Case confirmed',
                                                  'Past monitoring period',
                                                  'Meets criteria to discontinue isolation',
                                                  'Deceased',
                                                  'Duplicate',
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

  %i[address_state
     ethnicity
     monitored_address_state
     preferred_contact_method
     preferred_contact_time
     sex].each do |enum_field|
    validates enum_field, on: :api, inclusion: {
      in: VALID_ENUMS[enum_field],
      message: "is not an acceptable value, acceptable values are: '#{VALID_ENUMS[enum_field].join("', '")}'"
    }, allow_blank: true
  end

  %i[primary_telephone
     secondary_telephone].each do |phone_field|
    validates phone_field, on: :api, phone_number: true
  end

  %i[date_of_birth
     last_date_of_exposure
     symptom_onset].each do |date_field|
    validates date_field, on: :api, date: true
  end

  %i[address_state
     date_of_birth
     first_name
     last_name].each do |required_field|
    validates required_field, on: :api, presence: { message: 'is required' }
  end

  validates :symptom_onset,
            on: :api,
            presence: { message: "is required when 'Isolation' is 'true'" },
            if: -> { isolation }

  validates :last_date_of_exposure,
            on: :api,
            presence: { message: "is required when 'Isolation' is 'false'" },
            if: -> { !isolation }

  validates :email, on: :api, email: true

  validates :assigned_user, numericality: { only_integer: true, allow_nil: true, greater_than: 0, less_than_or_equal_to: 9999 }

  validates_with PrimaryContactValidator, on: :api
  validates_with PatientDateValidator

  belongs_to :responder, class_name: 'Patient'
  belongs_to :creator, class_name: 'User'
  has_many :dependents, class_name: 'Patient', foreign_key: 'responder_id'
  has_many :assessments
  belongs_to :jurisdiction
  has_many :histories
  has_many :transfers
  has_many :laboratories
  has_many :close_contacts

  before_save :set_time_zone_offset
  around_save :inform_responder, if: :responder_id_changed?
  around_destroy :inform_responder

  accepts_nested_attributes_for :laboratories

  # Most recent assessment
  def latest_assessment
    assessments.order(created_at: :desc).first
  end

  # Most recent transfer
  def latest_transfer
    transfers.order(created_at: :desc).first
  end

  # Patients who are eligible for reminders
  #
  # GENERAL SCOPE OVERVIEW:
  # - Everything is before the OR is essentially checking if the HoH or the patient
  #   who isn't in a household is eligible on their own.
  # - Everything within the OR is checking if the HoH has any DEPENDENTS (excluding self)
  #   that would make the HoH eligible to receive notifications for them.
  scope :reminder_eligible, lambda {
    monitoring_open
      .joins(:dependents)
      .where('patients.id = patients.responder_id')
      .where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      .where(pause_notifications: false)
      .where(
        'patients.isolation = ? '\
        'OR patients.continuous_exposure = ? '\
        'OR patients.last_date_of_exposure >= ? '\
        'OR (patients.last_date_of_exposure IS NULL AND patients.created_at >= ?)',
        true,
        true,
        ADMIN_OPTIONS['monitoring_period_days'].days.ago.beginning_of_day,
        ADMIN_OPTIONS['monitoring_period_days'].days.ago.beginning_of_day
      )
      .where(
        # Converting to a timezone, then casting to date effectively gives us
        # the start of the day in that timezone to make comparisons with.
        'CONVERT_TZ(patients.latest_assessment_at, "+00:00", patients.time_zone_offset)'\
        ' < DATE(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) '\
        'OR patients.latest_assessment_at IS NULL',
        # After converting TIMESTAMP to DATE in the query, the below should effectively become the
        # beginning of the day of the current reporting period for the specific patient's timezone.
        # Example: 1 day reporting period => was patient last assessment before midnight today?
        # Example: 2 day reporting period => was patient last assessment before midnight yesterday?
        # Example: 7 day reporting period => was patient last assessment before midnight 6 days ago?
        (Time.now.getlocal('-00:00') + 1.day - ADMIN_OPTIONS['reporting_period_minutes'].minutes).utc
      )
      .where(
        'patients.last_assessment_reminder_sent <= ? '\
        'OR patients.last_assessment_reminder_sent IS NULL',
        12.hours.ago
      )
      .within_preferred_contact_time
      .or(
        # This OR is checking if the HoH has any dependents that make them eligible to
        # recieve notifications on the dependent's behalf.
        # The joined table is referred to as `dependents_patients` and is used for all
        # checks made on the dependents. Anywhere the `patients` table is specified or
        # where a hash is used for a condition are checks made on the HoH.
        joins(:dependents)
          .where(purged: false)
          .where(head_of_household: true)
          .where('patients.id = patients.responder_id')
          .where(
            # Ignore any joined rows where the dependents_patients is the HoH itself.
            'dependents_patients.id != dependents_patients.responder_id'
          )
          .where.not(
            # HoH is unconditionally ineligible if it has any of these preferred contact methods
            preferred_contact_method: ['Unknown', 'Opt-out', '', nil]
          )
          .where(
            # HoH is unconditionally ineligible if it has paused notifications
            pause_notifications: false
          )
          .where('dependents_patients.monitoring = ?', true)
          .where('dependents_patients.purged = ?', false)
          .where(
            # This is basically the same as active_dependents()
            # but we cannot use it here because it's a method, and even if it was a scope
            # it wouldnt be using the join table, 'dependents_patients'.
            'dependents_patients.isolation = ? '\
            'OR dependents_patients.continuous_exposure = ? '\
            'OR dependents_patients.last_date_of_exposure >= ? '\
            'OR (dependents_patients.last_date_of_exposure IS NULL AND dependents_patients.created_at >= ?)',
            true,
            true,
            ADMIN_OPTIONS['monitoring_period_days'].days.ago.beginning_of_day,
            ADMIN_OPTIONS['monitoring_period_days'].days.ago.beginning_of_day
          )
          .within_preferred_contact_time
      )
      .distinct
  }

  scope :within_preferred_contact_time, lambda {
    where(
      # If preferred contact time is X,
      # then valid contact hours in patient's timezone are Y.
      # 'Morning'   => 0800 - 1200
      # 'Afternoon' => 1200 - 1600
      # 'Evening'   => 1600 - 1900
      #  default    => 1100 - 1700
      '(patients.preferred_contact_time = "Morning"'\
      ' && HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) >= 8'\
      ' && HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) <= 12) '\
      'OR (patients.preferred_contact_time = "Afternoon"'\
      ' && HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) >= 12'\
      ' && HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) <= 16) '\
      'OR (patients.preferred_contact_time = "Evening"'\
      ' && HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) >= 16'\
      ' && HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) <= 19) '\
      'OR (HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) >= 11'\
      ' && HOUR(CONVERT_TZ(?, "+00:00", patients.time_zone_offset)) <= 17)',
      Time.now.getlocal('-00:00'), Time.now.getlocal('-00:00'),
      Time.now.getlocal('-00:00'), Time.now.getlocal('-00:00'),
      Time.now.getlocal('-00:00'), Time.now.getlocal('-00:00'),
      Time.now.getlocal('-00:00'), Time.now.getlocal('-00:00')
    )
  }

  # All individuals currently being monitored
  scope :monitoring_open, lambda {
    where(monitoring: true)
      .where(purged: false)
  }

  # All individuals currently not being monitored
  scope :monitoring_closed, lambda {
    where(monitoring: false)
  }

  # All individuals that have been closed (not including purged)
  scope :monitoring_closed_without_purged, lambda {
    where(monitoring: false)
      .where(purged: false)
  }

  # All individuals that have been closed (including purged)
  scope :monitoring_closed_with_purged, lambda {
    where(monitoring: false)
      .where(purged: true)
  }

  # Purgeable eligible (records that could be purged in the next purge run if they aren't edited again)
  # By using chronic to determine the date of the next purge, the last warning date can be determined from that context
  # The use of `yesterday` in the context of the next purge date ensures that it includes the same day when using `this` keyword
  scope :purge_eligible, lambda {
    where(monitoring: false)
      .where(purged: false)
      .where(continuous_exposure: false)
      .where('patients.updated_at < ?',
             ADMIN_OPTIONS['purgeable_after'].minutes.before(
               Chronic.parse('last ' + ADMIN_OPTIONS['weekly_purge_warning_date'], now:
                 Chronic.parse('this ' + ADMIN_OPTIONS['weekly_purge_date'], now:
                   Chronic.parse('yesterday')))
             ))
  }

  # Purged monitoree records
  scope :purged, lambda {
    where(purged: true)
  }

  # All individuals who are confirmed cases
  scope :confirmed_case, lambda {
    where(monitoring_reason: 'Case confirmed')
  }

  # Any individual who has any assessments still considered symptomatic (includes patients in both exposure & isolation workflows)
  scope :symptomatic, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(public_health_action: 'None')
      .where.not(symptom_onset: nil)
      .distinct
  }

  # Individuals who have reported recently and are not symptomatic (includes patients in both exposure & isolation workflows)
  scope :asymptomatic, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(public_health_action: 'None')
      .where(symptom_onset: nil)
      .where('latest_assessment_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(public_health_action: 'None')
        .where(symptom_onset: nil)
        .where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      )
      .distinct
  }

  # Non reporting asymptomatic individuals (includes patients in both exposure & isolation workflows)
  scope :non_reporting, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(public_health_action: 'None')
      .where(symptom_onset: nil)
      .where(latest_assessment_at: nil)
      .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(public_health_action: 'None')
        .where(symptom_onset: nil)
        .where('latest_assessment_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
        .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      )
      .distinct
  }

  # Any individual who is currently under investigation (exposure workflow only)
  scope :exposure_under_investigation, lambda {
    where(isolation: false)
      .where(monitoring: true)
      .where(purged: false)
      .where.not(public_health_action: 'None')
      .distinct
  }

  # Any individual who has any assessments still considered symptomatic (exposure workflow only)
  scope :exposure_symptomatic, lambda {
    where(isolation: false).symptomatic.distinct
  }

  # Non reporting asymptomatic individuals (exposure workflow only)
  scope :exposure_non_reporting, lambda {
    where(isolation: false).non_reporting.distinct
  }

  # Individuals who have reported recently and are not symptomatic (exposure workflow only)
  scope :exposure_asymptomatic, lambda {
    where(isolation: false).asymptomatic.distinct
  }

  # Individuals that meet the asymptomatic recovery definition (isolation workflow only)
  scope :isolation_asymp_non_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where(symptom_onset: nil)
      .where.not(latest_assessment_at: nil)
      .where('latest_positive_lab_at < ?', 10.days.ago)
      .where('extended_isolation IS NULL OR extended_isolation < ?', Date.today)
      .distinct
  }

  # Individuals that meet the symptomatic non test based review requirement (isolation workflow only)
  scope :isolation_symp_non_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where('symptom_onset <= ?', 10.days.ago)
      .where(latest_fever_or_fever_reducer_at: nil)
      .where('extended_isolation IS NULL OR extended_isolation < ?', Date.today)
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: true)
        .where('symptom_onset <= ?', 10.days.ago)
        .where('latest_fever_or_fever_reducer_at < ?', 24.hours.ago)
        .where('extended_isolation IS NULL OR extended_isolation < ?', Date.today)
      )
      .distinct
  }

  # Individuals that meet the test based review requirement (isolation workflow only)
  scope :isolation_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where.not(latest_assessment_at: nil)
      .where(latest_fever_or_fever_reducer_at: nil)
      .where('negative_lab_count >= ?', 2)
      .where('extended_isolation IS NULL OR extended_isolation < ?', Date.today)
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: true)
        .where.not(latest_assessment_at: nil)
        .where('latest_fever_or_fever_reducer_at < ?', 24.hours.ago)
        .where('negative_lab_count >= ?', 2)
        .where('extended_isolation IS NULL OR extended_isolation < ?', Date.today)
      )
      .distinct
  }

  # Individuals in the isolation workflow that require review (isolation workflow only)
  scope :isolation_requiring_review, lambda {
    isolation_asymp_non_test_based
      .or(
        isolation_symp_non_test_based
      )
      .or(
        isolation_test_based
      )
      .distinct
  }

  # Individuals not meeting review but are reporting (isolation workflow only)
  scope :isolation_reporting, lambda {
    where.not(id: Patient.unscoped.isolation_requiring_review)
         .where(monitoring: true)
         .where(purged: false)
         .where(isolation: true)
         .where('latest_assessment_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
         .or(
           where.not(id: Patient.unscoped.isolation_requiring_review)
           .where(monitoring: true)
           .where(purged: false)
           .where(isolation: true)
           .where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
         )
         .distinct
  }

  # Individuals not meeting review and are not reporting (isolation workflow only)
  scope :isolation_non_reporting, lambda {
    where.not(id: Patient.unscoped.isolation_requiring_review)
         .where(monitoring: true)
         .where(purged: false)
         .where(isolation: true)
         .where(latest_assessment_at: nil)
         .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
         .or(
           where.not(id: Patient.unscoped.isolation_requiring_review)
           .where(monitoring: true)
           .where(purged: false)
           .where(isolation: true)
           .where('latest_assessment_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
           .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
         )
         .distinct
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
    when 'Total'
      all
    else
      none
    end
  }

  # All individuals closed within the given time frame
  scope :closed_in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('patients.closed_at >= ?', 24.hours.ago)
    when 'Last 14 Days'
      where('patients.closed_at >= ? AND patients.closed_at < ?', 14.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Total'
      all
    else
      none
    end
  }

  # Gets the current date in the patient's timezone
  def curr_date_in_timezone
    Time.now.getlocal(address_timezone_offset)
  end

  # Checks is at the end of or past their monitoring period
  def end_of_monitoring_period?
    return false if continuous_exposure

    monitoring_period_days = ADMIN_OPTIONS['monitoring_period_days'].days

    # If there is a last date of exposure - base monitoring period off of that date
    monitoring_end_date = if !last_date_of_exposure.nil?
                            last_date_of_exposure.beginning_of_day + monitoring_period_days
                          else
                            # Otherwise, if there is no last date of exposure - base monitoring period off of creation date
                            created_at.beginning_of_day + monitoring_period_days
                          end

    # If it is the last day of or past the monitoring period
    # NOTE: beginning_of_day is used as monitoring period is based of date not the specific time
    curr_date_in_timezone.beginning_of_day >= monitoring_end_date
  end

  # Patients are eligible to be automatically closed by the system IF:
  #  - in exposure workflow
  #     AND
  #  - asymptomatic
  #     AND
  #  - submitted an assessment today already (based on their timezone)
  #     AND
  #  - not in continuous exposure
  #     AND
  #  - on the last day of or past their monitoring period
  def self.close_eligible
    exposure_asymptomatic
      .where(continuous_exposure: false)
      .select do |patient|
        # Submitted an assessment today AND is at the end of or past their monitoring period
        (!patient.latest_assessment_at.nil? &&
          patient.latest_assessment_at.getlocal(patient.address_timezone_offset) >= patient.curr_date_in_timezone.beginning_of_day &&
          patient.end_of_monitoring_period?)
      end
  end

  # Order individuals based on their public health assigned risk assessment
  def self.order_by_risk(asc: true)
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

  # Check for potential duplicate records. Duplicate criteria is as follows:
  # - matching first name, last name, sex, and DoB
  # OR
  # - matching state/local id
  def self.duplicate_data(first_name, last_name, sex, date_of_birth, user_defined_id_statelocal)
    dup_info = where('first_name = ?', first_name)
               .where('last_name = ?', last_name)
               .where('sex = ?', sex)
               .where('date_of_birth = ?', date_of_birth)

    dup_statelocal_id = where('user_defined_id_statelocal = ?', user_defined_id_statelocal&.to_s&.strip)

    # Get fields that have matching values
    duplicate_field_data = []
    duplicate_field_data << { count: dup_info.count, fields: ['First Name', 'Last Name', 'Sex', 'Date of Birth'] } if dup_info.present?
    duplicate_field_data << { count: dup_statelocal_id.count, fields: ['State/Local ID'] } if dup_statelocal_id.present?

    { is_duplicate: duplicate_field_data.length.positive?, duplicate_field_data: duplicate_field_data }
  end

  # Get the patient who is responsible for responding on this phone number
  # This should only be true for one patient per phone number
  def self.responder_for_number(tel_number)
    return nil if tel_number.nil?

    where('primary_telephone = ?', tel_number)
      .where('responder_id = id')
  end

  # Get the patient who is responsible for responding at this email address
  # This should only be true for one patient per email
  def self.responder_for_email(email)
    return nil if email.nil?

    where('email = ?', email)
      .where('responder_id = id')
  end

  # True if this person is responsible for reporting
  def self_reporter_or_proxy?
    responder_id == id
  end

  # Patient name to be displayed in linelist
  def displayed_name
    first_name.present? || last_name.present? ? "#{last_name}#{first_name.blank? ? '' : ', ' + first_name}" : 'NAME NOT PROVIDED'
  end

  # Allow information on the monitoree's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Get all dependents (including self if id = responder_id) that are being actively monitored, meaning:
  # - not purged AND not closed (monitoring = true)
  #  AND
  #    - in continuous exposure
  #     OR
  #    - in isolation
  #     OR
  #    - within monitoring period based on LDE
  #     OR
  #    - within monitoring period based on creation date if no LDE specified
  def active_dependents
    monitoring_days_ago = ADMIN_OPTIONS['monitoring_period_days'].days.ago.beginning_of_day
    dependents.where(purged: false, monitoring: true)
              .where('isolation = ? OR continuous_exposure = ? OR last_date_of_exposure >= ? OR (last_date_of_exposure IS NULL AND created_at >= ?)',
                     true, true, monitoring_days_ago, monitoring_days_ago)
  end

  # Get all dependents (excluding self if id = responder_id) that are being monitored
  def active_dependents_exclude_self
    active_dependents.where.not(id: id)
  end

  # Get this patient's dependents excluding itself
  def dependents_exclude_self
    dependents.where.not(id: id)
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    return 'Continuous Exposure' if continuous_exposure
    return (last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s if last_date_of_exposure.present?

    # Check for created_at is necessary here because custom as_json is automatically called when enrolling a new patient, which calls this method indirectly.
    return (created_at.to_date + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s if created_at.present?
  end

  # Date when patient is expected to be purged
  def expected_purge_date
    (updated_at + ADMIN_OPTIONS['purgeable_after'].minutes)&.rfc2822
  end

  # Send initial enrollment notification via patient's preferred contact method
  def send_enrollment_notification
    return if ['Unknown', 'Opt-out', '', nil].include?(preferred_contact_method)

    if email.present? && preferred_contact_method == 'E-mailed Web Link'
      # deliver_later forces the use of ActiveJob
      # sidekiq and redis should be running for this to work
      # If these are not running, all jobs will be completed when services start
      PatientMailer.enrollment_email(self).deliver_later if ADMIN_OPTIONS['enable_email'] && !Rails.env.test?
    elsif primary_telephone.present? && preferred_contact_method == 'SMS Texted Weblink'
      # deliver_later forces the use of ActiveJob
      # sidekiq and redis should be running for this to work
      # If these are not running, all jobs will be completed when services start
      PatientMailer.enrollment_sms_weblink(self).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
    elsif primary_telephone.present? && preferred_contact_method == 'SMS Text-message'
      # deliver_later forces the use of ActiveJob
      # sidekiq and redis should be running for this to work
      # If these are not running, all jobs will be completed when services start
      PatientMailer.enrollment_sms_text_based(self).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
    end
  end

  # Send a daily assessment to this monitoree (if currently eligible). By setting send_now to true, an assessment
  # will be sent immediately without any consideration of the monitoree's preferred_contact_time.
  def send_assessment(send_now: false)
    # Stop execution if in CI
    return if Rails.env.test?

    # Determine if it is yet an appropriate time to send this person a message.
    unless send_now
      # Local "hour" (defaults to eastern if timezone cannot be determined)
      hour = Time.now.getlocal(address_timezone_offset).hour

      # These are the hours that we consider to be morning, afternoon and evening
      morning = (8..12)
      afternoon = (12..16)
      evening = (16..19)
      case preferred_contact_time&.downcase
      when 'morning'
        return unless morning.include? hour
      when 'afternoon'
        return unless afternoon.include? hour
      when 'evening'
        return unless evening.include? hour
      else
        # Default to roughly afternoon if preferred contact time is not specified
        return unless (11..17).include? hour
      end
    end

    if preferred_contact_method&.downcase == 'sms text-message' && ADMIN_OPTIONS['enable_sms']
      PatientMailer.assessment_sms(self).deliver_later
    elsif preferred_contact_method&.downcase == 'sms texted weblink' && ADMIN_OPTIONS['enable_sms']
      PatientMailer.assessment_sms_weblink(self).deliver_later
    elsif preferred_contact_method&.downcase == 'telephone call' && ADMIN_OPTIONS['enable_voice']
      PatientMailer.assessment_voice(self).deliver_later
    elsif preferred_contact_method&.downcase == 'e-mailed web link' && ADMIN_OPTIONS['enable_email']
      PatientMailer.assessment_email(self).deliver_later if email.present?
    end
  end

  # Patient initials and age
  def initials_age(separator = '')
    "#{initials}#{separator}#{(calc_current_age || 0).to_s.truncate(3, omission: nil)}"
  end

  # Patient initials
  def initials
    "#{first_name&.gsub(/[^A-Za-z]/i, '')&.first || ''}#{last_name&.gsub(/[^A-Za-z]/i, '')&.first || ''}"
  end

  # Return the calculated age based on the date of birth
  def calc_current_age
    Patient.calc_current_age_base(provided_date_of_birth: date_of_birth)
  end

  def self.calc_current_age_fhir(birth_date)
    return nil if birth_date.nil?

    begin
      date_of_birth = DateTime.strptime(birth_date, '%Y-%m-%d')
    rescue ArgumentError
      begin
        date_of_birth = DateTime.strptime(birth_date, '%Y-%m')
      rescue ArgumentError
        # Raise if this fails because provided date of birth is not in the valid FHIR date format
        date_of_birth = DateTime.strptime(birth_date, '%Y')
      end
    end
    Patient.calc_current_age_base(provided_date_of_birth: date_of_birth)
  end

  def self.calc_current_age_base(provided_date_of_birth: nil)
    # Make sure to calculate today using UTC for consistency
    today = Time.now.utc.to_date
    dob = provided_date_of_birth || today
    age = today.year - dob.year
    age -= 1 if
        (dob.month > today.month) ||
        ((dob.month >= today.month) && (dob.day > today.day))
    age
  end

  # Determine the proper language for sending reports to this monitoree
  def select_language
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    lang = PatientHelper.languages(primary_language)&.dig(:code)&.to_sym || :en
    lang = :en unless %i[en es es-PR so fr].include?(lang)
    lang
  end

  # Determine if this patient is eligible for receiving daily report messages; return
  # a boolean result to switch on, and a tailored message useful for user interfaces.
  def report_eligibility
    report_cutoff_time = (Time.now.getlocal(address_timezone_offset) + 1.day - ADMIN_OPTIONS['reporting_period_minutes'].minutes).beginning_of_day.utc
    reporting_period = (ADMIN_OPTIONS['monitoring_period_days'] + 1).days.ago
    eligible = true
    sent = false
    reported = false
    household = false
    messages = []

    # Workflow agnostic conditions

    # Can't send messages to monitorees that are purged (this should never actually show up)
    if purged
      eligible = false
      messages << { message: 'Monitoree was purged', datetime: nil }
    end

    # Can't send to household members
    if id != responder_id
      eligible = false
      household = true
      messages << { message: 'Monitoree is within a household, so the HoH will receive notifications instead', datetime: nil }
    end

    # Can't send messages to monitorees that are on the closed line list and have no active dependents.
    if !monitoring && active_dependents.empty?
      eligible = false

      # If this person has dependents (is a HoH)
      is_hoh = dependents_exclude_self.exists?
      message = "Monitoree is not currently being monitored #{is_hoh ? 'and has no actively monitored household members' : ''}"
      messages << { message: message, datetime: nil }
    end

    # Can't send messages if notifications are paused
    if pause_notifications
      eligible = false
      messages << { message: 'Monitoree\'s notifications are paused', datetime: nil }
    end

    # Has an ineligible preferred contact method
    if ['Unknown', 'Opt-out', '', nil].include?(preferred_contact_method)
      eligible = false
      messages << { message: "Monitoree has an ineligible preferred contact method (#{preferred_contact_method || 'Missing'})", datetime: nil }
    end

    # Exposure workflow specific conditions
    unless isolation
      # Monitoring period has elapsed
      start_of_exposure = last_date_of_exposure || created_at
      no_active_dependents = !active_dependents_exclude_self.exists?
      if start_of_exposure < reporting_period && !continuous_exposure && no_active_dependents
        eligible = false
        messages << { message: "Monitoree\'s monitoring period has elapsed and continuous exposure is not enabled", datetime: nil }
      end
    end

    # Has already been contacted today
    if !last_assessment_reminder_sent.nil? && last_assessment_reminder_sent >= 12.hours.ago
      eligible = false
      sent = true
      messages << { message: 'Monitoree has been contacted recently', datetime: last_assessment_reminder_sent }
    end

    # Has already reported today
    if !latest_assessment_at.nil? && latest_assessment_at >= report_cutoff_time
      eligible = false
      reported = true
      messages << { message: 'Monitoree has already reported today', datetime: latest_assessment_at }
    end

    # Rough estimate of next contact time
    if eligible
      messages << case preferred_contact_time
                  when 'Morning'
                    { message: '8:00 AM local time (Morning)', datetime: nil }
                  when 'Afternoon'
                    { message: '12:00 PM local time (Afternoon)', datetime: nil }
                  when 'Evening'
                    { message: '4:00 PM local time (Evening)', datetime: nil }
                  else
                    { message: 'Today', datetime: nil }
                  end
    end

    { eligible: eligible, sent: sent, reported: reported, messages: messages, household: household }
  end

  # Returns a representative FHIR::Patient for an instance of a Sara Alert Patient. Uses US Core
  # extensions for sex, race, and ethnicity.
  # https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-patient.html
  def as_fhir
    FHIR::Patient.new(
      meta: FHIR::Meta.new(lastUpdated: updated_at.strftime('%FT%T%:z')),
      id: id,
      active: monitoring,
      name: [FHIR::HumanName.new(given: [first_name, middle_name].reject(&:blank?), family: last_name)],
      telecom: [
        primary_telephone ? FHIR::ContactPoint.new(system: 'phone', value: primary_telephone, rank: 1) : nil,
        secondary_telephone ? FHIR::ContactPoint.new(system: 'phone', value: secondary_telephone, rank: 2) : nil,
        email ? FHIR::ContactPoint.new(system: 'email', value: email, rank: 1) : nil
      ].reject(&:nil?),
      birthDate: date_of_birth&.strftime('%F'),
      address: [
        FHIR::Address.new(
          line: [address_line_1, address_line_2].reject(&:blank?),
          city: address_city,
          district: address_county,
          state: address_state,
          postalCode: address_zip
        )
      ],
      communication: [
        language_coding(primary_language) ? FHIR::Patient::Communication.new(
          language: FHIR::CodeableConcept.new(coding: [language_coding(primary_language)]),
          preferred: interpretation_required
        ) : nil
      ].reject(&:nil?),
      extension: [
        us_core_race(white, black_or_african_american, american_indian_or_alaska_native, asian, native_hawaiian_or_other_pacific_islander),
        us_core_ethnicity(ethnicity),
        us_core_birthsex(sex),
        to_preferred_contact_method_extension(preferred_contact_method),
        to_preferred_contact_time_extension(preferred_contact_time),
        to_symptom_onset_date_extension(symptom_onset),
        to_last_exposure_date_extension(last_date_of_exposure),
        to_isolation_extension(isolation),
        to_string_extension(jurisdiction.jurisdiction_path_string, 'full-assigned-jurisdiction-path')
      ].reject(&:nil?)
    )
  end

  # Create a hash of atttributes that corresponds to a Sara Alert Patient (and can be used to
  # create new ones, or update existing ones), using the given FHIR::Patient.
  def self.from_fhir(patient, default_jurisdiction_id)
    {
      monitoring: patient&.active.nil? ? false : patient.active,
      first_name: patient&.name&.first&.given&.first,
      middle_name: patient&.name&.first&.given&.second,
      last_name: patient&.name&.first&.family,
      primary_telephone: PatientHelper.from_fhir_phone_number(patient&.telecom&.select { |t| t&.system == 'phone' }&.first&.value),
      secondary_telephone: PatientHelper.from_fhir_phone_number(patient&.telecom&.select { |t| t&.system == 'phone' }&.second&.value),
      email: patient&.telecom&.select { |t| t&.system == 'email' }&.first&.value,
      date_of_birth: patient&.birthDate,
      age: Patient.calc_current_age_fhir(patient&.birthDate),
      address_line_1: patient&.address&.first&.line&.first,
      address_line_2: patient&.address&.first&.line&.second,
      address_city: patient&.address&.first&.city,
      address_county: patient&.address&.first&.district,
      address_state: patient&.address&.first&.state,
      address_zip: patient&.address&.first&.postalCode,
      monitored_address_line_1: patient&.address&.first&.line&.first,
      monitored_address_line_2: patient&.address&.first&.line&.second,
      monitored_address_city: patient&.address&.first&.city,
      monitored_address_county: patient&.address&.first&.district,
      monitored_address_state: patient&.address&.first&.state,
      monitored_address_zip: patient&.address&.first&.postalCode,
      primary_language: patient&.communication&.first&.language&.coding&.first&.display,
      interpretation_required: patient&.communication&.first&.preferred,
      white: PatientHelper.race_code?(patient, '2106-3'),
      black_or_african_american: PatientHelper.race_code?(patient, '2054-5'),
      american_indian_or_alaska_native: PatientHelper.race_code?(patient, '1002-5'),
      asian: PatientHelper.race_code?(patient, '2028-9'),
      native_hawaiian_or_other_pacific_islander: PatientHelper.race_code?(patient, '2076-8'),
      ethnicity: PatientHelper.ethnicity(patient),
      sex: PatientHelper.birthsex(patient),
      preferred_contact_method: PatientHelper.from_preferred_contact_method_extension(patient),
      preferred_contact_time: PatientHelper.from_preferred_contact_time_extension(patient),
      symptom_onset: PatientHelper.from_symptom_onset_date_extension(patient),
      last_date_of_exposure: PatientHelper.from_last_exposure_date_extension(patient),
      isolation: PatientHelper.from_isolation_extension(patient),
      jurisdiction_id: PatientHelper.from_full_assigned_jurisdiction_path_extension(patient, default_jurisdiction_id)
    }
  end

  # Override as_json to include linelist
  def as_json(options = {})
    super((options || {}).merge(methods: :linelist))
  end

  def set_time_zone_offset
    self.time_zone_offset = address_timezone_offset
  end

  def address_timezone_offset
    if monitored_address_state.present?
      timezone_for_state(monitored_address_state)
    elsif address_state.present?
      timezone_for_state(address_state)
    else
      timezone_for_state('massachusetts')
    end
  end

  # Creates a diff between a patient before and after updates, and creates a detailed record edit History item with the changes.
  def self.detailed_history_edit(patient_before, patient_after, user_email, allowed_fields, is_api_edit: false)
    diffs = patient_diff(patient_before, patient_after, allowed_fields)
    return if diffs.length.zero?

    pretty_diff = diffs.collect { |d| "#{d[:attribute].to_s.humanize} (\"#{d[:before]}\" to \"#{d[:after]}\")" }
    comment = is_api_edit ? 'Monitoree record edited via API. ' : 'User edited a monitoree record. '
    comment += "Changes were: #{pretty_diff.join(', ')}."
    History.record_edit(patient: patient_after, created_by: user_email, comment: comment)
  end

  # Construct a diff for a patient update to keep track of changes
  def self.patient_diff(patient_before, patient_after, allowed_fields)
    diffs = []
    allowed_fields&.keys&.each do |attribute|
      next if patient_before[attribute] == patient_after[attribute]

      diffs << {
        attribute: attribute,
        before: attribute == :jurisdiction_id ? Jurisdiction.find(patient_before[attribute])[:path] : patient_before[attribute],
        after: attribute == :jurisdiction_id ? Jurisdiction.find(patient_after[attribute])[:path] : patient_after[attribute]
      }
    end
    diffs
  end

  # Use the cached attribute if it exists, if not query with count for performance
  # instead of loading all dependents.
  def head_of_household?
    return head_of_household unless head_of_household.nil?

    dependents_exclude_self.where(purged: false).size.positive?
  end

  def inform_responder
    initial_responder = responder_id_was
    # Yield to save or destroy, depending on which callback invokes this method
    yield

    return if responder.nil?

    # update the initial responder if it changed
    Patient.where(purged: false).find(initial_responder).refresh_head_of_household if !initial_responder.nil? && initial_responder != responder.id
    # update the current responder
    responder.refresh_head_of_household
  end

  def refresh_head_of_household
    hoh = dependents_exclude_self.where(purged: false).size.positive?
    update(head_of_household: hoh) unless head_of_household == hoh
  end

  # Create a secure random token to act as the monitoree's password when they submit assessments
  # This gets included in the URL sent to the monitoree to allow them to report without having to type in a password
  def new_submission_token
    token = nil
    loop do
      token = SecureRandom.urlsafe_base64[0, 10]
      break unless Patient.where(submission_token: token).any?
    end
    token
  end
end
