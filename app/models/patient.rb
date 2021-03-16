# frozen_string_literal: true

# Patient: patient model
# rubocop:disable Metrics/ClassLength
class Patient < ApplicationRecord
  include PatientHelper
  include PatientDetailsHelper
  include ValidationHelper
  include ActiveModel::Validations
  include FhirHelper

  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  validates :monitoring_reason, inclusion: {
    in: VALID_PATIENT_ENUMS[:monitoring_reason],
    message: "is not an acceptable value, acceptable values are: '#{VALID_PATIENT_ENUMS[:monitoring_reason].reject(&:blank?).join("', '")}'"
  }
  validates :monitoring_plan, inclusion: {
    in: VALID_PATIENT_ENUMS[:monitoring_plan],
    message: "is not an acceptable value, acceptable values are: '#{VALID_PATIENT_ENUMS[:monitoring_plan].reject(&:blank?).join("', '")}'"
  }

  validates :exposure_risk_assessment, inclusion: {
    in: VALID_PATIENT_ENUMS[:exposure_risk_assessment],
    message: "is not an acceptable value, acceptable values are: '#{VALID_PATIENT_ENUMS[:exposure_risk_assessment].reject(&:blank?).join("', '")}'"
  }

  %i[address_state
     monitored_address_state
     foreign_monitored_address_state
     additional_planned_travel_destination_state
     ethnicity
     preferred_contact_method
     preferred_contact_time
     sex
     primary_telephone_type
     secondary_telephone_type
     additional_planned_travel_type
     case_status].each do |enum_field|
    validates enum_field, on: %i[api import], inclusion: {
      in: VALID_PATIENT_ENUMS[enum_field],
      message: "is not an acceptable value, acceptable values are: '#{VALID_PATIENT_ENUMS[enum_field].reject(&:blank?).join("', '")}'"
    }
  end

  %i[primary_telephone
     secondary_telephone].each do |phone_field|
    validates phone_field, on: %i[api import], phone_number: true
  end

  %i[date_of_birth
     last_date_of_exposure
     symptom_onset
     additional_planned_travel_start_date
     additional_planned_travel_end_date
     date_of_departure
     date_of_arrival].each do |date_field|
    validates date_field, on: %i[api import], date: true
  end

  %i[date_of_birth
     first_name
     last_name].each do |required_field|
    validates required_field, on: :api, presence: { message: 'is required' }
  end

  validates :address_state,
            on: :api,
            presence: { message: 'is required unless a "Foreign Address Country" is specified' },
            unless: -> { foreign_address_country.present? }

  validates :symptom_onset,
            on: :api,
            presence: { message: "is required when 'Isolation' is 'true'" },
            if: -> { isolation }

  validates :last_date_of_exposure,
            on: :api,
            presence: { message: "is required when 'Isolation' is 'false' and 'Continuous Exposure' is 'false'" },
            if: -> { !isolation && !continuous_exposure }

  validates :continuous_exposure,
            on: :api,
            absence: { message: "cannot be 'true' when 'Last Date of Exposure' is specified" },
            if: -> { last_date_of_exposure.present? }

  validates :email, on: %i[api import], email: true

  validates :assigned_user, numericality: { only_integer: true,
                                            allow_nil: true,
                                            greater_than: 0,
                                            less_than_or_equal_to: 999_999,
                                            message: 'is not valid, acceptable values are numbers between 1-999999' }

  validates_with PrimaryContactValidator, on: %i[api import]
  validates_with RaceValidator, on: %i[api import]

  # NOTE: Commented out until additional testing
  # validates_with PatientDateValidator

  belongs_to :responder, class_name: 'Patient'
  belongs_to :creator, class_name: 'User'
  has_many :dependents, class_name: 'Patient', foreign_key: 'responder_id'
  has_many :assessments
  belongs_to :jurisdiction
  has_many :histories
  has_many :transfers
  has_many :laboratories
  has_many :vaccines
  has_many :close_contacts
  has_many :contact_attempts

  before_update :set_time_zone, if: proc { |patient|
    patient.monitored_address_state_changed? || patient.address_state_changed?
  }
  before_create :set_time_zone

  around_save :inform_responder, if: :responder_id_changed?
  around_destroy :inform_responder
  before_update :handle_update

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
  scope :reminder_eligible, lambda {
    where(purged: false)
      .where(pause_notifications: false)
      .where('patients.id = patients.responder_id')
      .where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
      .where('last_assessment_reminder_sent <= ? OR last_assessment_reminder_sent IS NULL', 12.hours.ago)
      .where('latest_assessment_at < ? OR latest_assessment_at IS NULL', Time.now.in_time_zone('Eastern Time (US & Canada)').beginning_of_day)
  }

  # Patients who are eligible for reminders
  #
  # GENERAL SCOPE OVERVIEW:
  # - Everything before the OR is essentially checking if the HoH or the patient
  #   who isn't in a household is eligible on their own.
  # - Everything within the OR is checking if the HoH has any DEPENDENTS (excluding self)
  #   that would make the HoH eligible to receive notifications for them.
  scope :better_reminder_eligible, lambda {
    joins(:dependents)
      .monitoring_open
      .within_preferred_contact_time
      .has_not_reported_recently
      .is_being_monitored
      .has_usable_preferred_contact_method
      .where('patients.id = patients.responder_id')
      .where(pause_notifications: false)
      .reminder_not_sent_recently
      .or(has_eligible_dependents)
  }

  # Pateints should be reminded to report once within the reporting period.
  #
  # Period is based on the reporting_period_minutes, but is rounded by days.
  #
  # Example: 1 day reporting period => was patient last reminder before midnight today?
  # Example: 2 day reporting period => was patient last reminder before midnight yesterday?
  # Example: 7 day reporting period => was patient last reminder before midnight 6 days ago?
  scope :reminder_not_sent_recently, lambda {
    where(
      # Converting to a timezone, then casting to date effectively gives us
      # the start of the day in that timezone to make comparisons with.
      'patients.last_assessment_reminder_sent IS NULL OR '\
      'DATE_ADD('\
      '    DATE(CONVERT_TZ(patients.last_assessment_reminder_sent, "UTC", patients.time_zone)),'\
      '    INTERVAL ? DAY'\
      ') < CONVERT_TZ(?, "UTC", patients.time_zone)',
      (ADMIN_OPTIONS['reporting_period_minutes'] / 1440).to_i,
      Time.now.getlocal('-00:00')
    )
  }

  # Non-eligible contact methods are: ['Unknown', 'Opt-out', '', nil]
  scope :has_usable_preferred_contact_method, lambda {
    where.not(preferred_contact_method: ['Unknown', 'Opt-out', '', nil])
  }

  # Check if the HoH has any dependents that make them eligible to
  # recieve notifications on the dependent's behalf.
  # The joined table is referred to as `dependents_patients` and is used for all
  # checks made on the dependents. Anywhere the `patients` table is specified or
  # where a hash is used for a condition are checks made on the HoH.
  #
  # A dependent patient makes the HoH reminder eligible if:
  # - HoH is not purged
  # - HoH has a usable preferred contact method
  # - HoH has not paused notifications
  # - current HoH local time is within the preferred contact time window
  # - patient has monitoring ON
  # - patient is not purged
  # - patient is in isolation
  #   OR
  #   patient is in continuous exposure
  #   OR
  #   patient last date of exposure is on or after (today - monitoring_period_days)
  #   OR
  #   patient last date of exposure is null and created at of exposure is on or after (today - monitoring_period_days)
  scope :has_eligible_dependents, lambda {
    joins(:dependents)
      .where(purged: false)
      .where(head_of_household: true)
      .where('patients.id = patients.responder_id')
      .where(
        # Ignore any joined rows where the dependents_patients is the HoH itself.
        'dependents_patients.id != dependents_patients.responder_id'
      )
      .has_usable_preferred_contact_method
      .where(
        # HoH is unconditionally ineligible if it has paused notifications
        pause_notifications: false
      )
      .where('dependents_patients.monitoring = ?', true)
      .where('dependents_patients.purged = ?', false)
      .where(
        'dependents_patients.isolation = ? '\
        'OR dependents_patients.continuous_exposure = ? '\
        'OR dependents_patients.last_date_of_exposure >= DATE_SUB(DATE(CONVERT_TZ(?, "UTC", dependents_patients.time_zone)), INTERVAL ? DAY) '\
        'OR ('\
        '  dependents_patients.last_date_of_exposure IS NULL '\
        '  AND dependents_patients.created_at >= DATE_SUB(DATE(CONVERT_TZ(?, "UTC", dependents_patients.time_zone)), INTERVAL ? DAY)'\
        ')',
        true,
        true,
        Time.now.getlocal('-00:00'),
        ADMIN_OPTIONS['monitoring_period_days'],
        Time.now.getlocal('-00:00'),
        ADMIN_OPTIONS['monitoring_period_days']
      )
      .within_preferred_contact_time
      .reminder_not_sent_recently
  }

  # Patients should be monitored are any of the below:
  # - In isolation
  # - In continuous exposure
  # - last date of exposure is on or after (today - monitoring_period_days)
  #   OR
  #   last date of exposure is null and created at of exposure is on or after (today - monitoring_period_days)
  scope :is_being_monitored, lambda {
    where(
      'patients.isolation = ? '\
      'OR patients.continuous_exposure = ? '\
      'OR patients.last_date_of_exposure >= DATE_SUB(DATE(CONVERT_TZ(?, "UTC", patients.time_zone)), INTERVAL ? DAY) '\
      'OR ('\
      '  patients.last_date_of_exposure IS NULL '\
      '  AND patients.created_at >= DATE_SUB(DATE(CONVERT_TZ(?, "UTC", patients.time_zone)), INTERVAL ? DAY)'\
      ')',
      true,
      true,
      Time.now.getlocal('-00:00'),
      ADMIN_OPTIONS['monitoring_period_days'],
      Time.now.getlocal('-00:00'),
      ADMIN_OPTIONS['monitoring_period_days']
    )
  }

  # A patient has not reported within the reporting period if either:
  # - last assessment is null
  # - latest assessment date is before the beginning of the day in patient local
  #   time for (time now - reporting_period_minutes).beginning of day
  scope :has_not_reported_recently, lambda {
    where(
      # Converting to a timezone, then casting to date effectively gives us
      # the start of the day in that timezone to make comparisons with.
      'patients.latest_assessment_at IS NULL OR '\
      'DATE_ADD('\
      '    DATE(CONVERT_TZ(patients.latest_assessment_at, "UTC", patients.time_zone)),'\
      '    INTERVAL ? DAY'\
      ') < CONVERT_TZ(?, "UTC", patients.time_zone)',
      # Example: 1 day reporting period => was patient last assessment before midnight today?
      # Example: 2 day reporting period => was patient last assessment before midnight yesterday?
      # Example: 7 day reporting period => was patient last assessment before midnight 6 days ago?
      (ADMIN_OPTIONS['reporting_period_minutes'] / 1440).to_i,
      Time.now.getlocal('-00:00')
    )
  }

  scope :within_preferred_contact_time, lambda {
    where(
      # If preferred contact time is X,
      # then valid contact hours in patient's timezone are Y.
      # 'Morning'   => 0800 - 1200
      # 'Afternoon' => 1200 - 1600
      # 'Evening'   => 1600 - 1900
      #  default    => 1200 - 1600
      '(patients.preferred_contact_time = "Morning"'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) >= 8'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) <= 12) '\
      'OR (patients.preferred_contact_time = "Afternoon"'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) >= 12'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) <= 16) '\
      'OR (patients.preferred_contact_time = "Evening"'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) >= 16'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) <= 19) '\
      'OR (patients.preferred_contact_time IS NULL'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) >= 12'\
      ' && HOUR(CONVERT_TZ(?, "UTC", patients.time_zone)) <= 16)',
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
  }

  # Convert Patient's latest_assessment_at from UTC to the Patient's local time
  # Is that time after the date (NOT TIME) of now UTC converted to the Patient's time zone
  # AND they have a latest_assessment_at set.
  scope :submitted_assessment_today, lambda {
    where(
      'CONVERT_TZ(patients.latest_assessment_at, "UTC", patients.time_zone)'\
      ' >= DATE(CONVERT_TZ(?, "+00:00", patients.time_zone))'\
      'AND CONVERT_TZ(patients.latest_assessment_at, "UTC", patients.time_zone)'\
      ' < DATE_ADD(DATE(CONVERT_TZ(?, "+00:00", patients.time_zone)), INTERVAL 1 DAY)',
      Time.now.getlocal('-00:00'),
      Time.now.getlocal('-00:00')
    )
      .where.not(latest_assessment_at: nil)
  }

  # Any individual who is currently under investigation (exposure workflow only)
  scope :exposure_under_investigation, lambda {
    where(isolation: false)
      .where(monitoring: true)
      .where(purged: false)
      .where.not(public_health_action: 'None')
  }

  # Any individual who has any assessments still considered symptomatic (exposure workflow only)
  scope :exposure_symptomatic, lambda {
    where(isolation: false).symptomatic
  }

  # Non reporting asymptomatic individuals (exposure workflow only)
  scope :exposure_non_reporting, lambda {
    where(isolation: false).non_reporting
  }

  # Individuals who have reported recently and are not symptomatic (exposure workflow only)
  scope :exposure_asymptomatic, lambda {
    where(isolation: false).asymptomatic
  }

  # Individuals that meet the asymptomatic recovery definition (isolation workflow only)
  scope :isolation_asymp_non_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where(symptom_onset: nil)
      .where.not(latest_assessment_at: nil)
      .where('first_positive_lab_at < ?', 10.days.ago)
      .where('extended_isolation IS NULL OR extended_isolation < ?', Date.today)
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
  }

  # Monitorees who have reported in the last hour that are considered symptomatic
  scope :recently_symptomatic, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where('latest_assessment_at >= ?', 60.minutes.ago)
      .where_assoc_exists(:assessments, &:symptomatic_last_hour)
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
    when 'Exposure Symptomatic'
      exposure_symptomatic
    when 'Exposure Non-Reporting'
      exposure_non_reporting
    when 'Exposure Asymptomatic'
      exposure_asymptomatic
    when 'Exposure PUI'
      exposure_under_investigation
    when 'Isolation Requiring Review'
      isolation_requiring_review
    when 'Isolation Non-Reporting'
      isolation_non_reporting
    when 'Isolation Reporting'
      isolation_reporting
    end
  }

  # All individuals with a last date of exposure within the given time frame
  scope :exposed_in_time_frame, lambda { |time_frame|
    where('last_date_of_exposure >= ?', time_frame)
  }

  # All individuals with a last date of exposure within the given time frame
  scope :symptom_onset_in_time_frame, lambda { |time_frame|
    where('symptom_onset >= ?', time_frame)
  }

  # All individuals enrolled within the given time frame
  scope :enrolled_in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('patients.created_at >= ?', 24.hours.ago)
    when 'Last 7 Days'
      where('patients.created_at >= ? AND patients.created_at < ?', 7.days.ago.to_date.to_datetime, Date.today.to_datetime)
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
    when 'Last 7 Days'
      where('patients.closed_at >= ? AND patients.closed_at < ?', 7.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Last 14 Days'
      where('patients.closed_at >= ? AND patients.closed_at < ?', 14.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Total'
      all
    else
      none
    end
  }

  # Criteria for this CDC quarantine guidance which can be found here:
  # https://www.cdc.gov/coronavirus/2019-ncov/more/scientific-brief-options-to-reduce-quarantine.html
  #
  # Record must:
  # - be unpurged, open, in exposure workflow, and not in continuous exposure
  # - has no symptomatic reports
  # - have reported within 10-13 days after their last date of exposure
  # - be 10 or more days past their last date of exposure
  scope :ten_day_quarantine_candidates, lambda { |user_curr_datetime|
    where(purged: false, monitoring: true, isolation: false, continuous_exposure: false)
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .where_assoc_exists(:assessments) do
        # CAST is necessary to guarantee correct comparison between datetime and date.
        where('CAST(assessments.created_at AS DATE) BETWEEN DATE_ADD(last_date_of_exposure, INTERVAL 10 DAY) '\
              'AND DATE_ADD(last_date_of_exposure, INTERVAL 13 DAY)')
      end
      .where('? >= DATE_ADD(patients.last_date_of_exposure, INTERVAL 10 DAY)', user_curr_datetime.to_date)
  }

  # Criteria for this CDC quarantine guidance which can be found here:
  # https://www.cdc.gov/coronavirus/2019-ncov/more/scientific-brief-options-to-reduce-quarantine.html
  #
  # Record must:
  # - be unpurged, open, in exposure workflow, and not in continuous exposure
  #-  has no symptomatic reports
  # - have reported within 7-9 days after their last date of exposure and
  # - be 7 or more days past their last date of exposure
  # - have a negative PCR or Antigen test that was collected between 5-9 days after their last date of exposure
  # rubocop:disable Style/MultilineBlockChain
  scope :seven_day_quarantine_candidates, lambda { |user_curr_datetime|
    where(purged: false, monitoring: true, isolation: false, continuous_exposure: false)
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .where_assoc_exists(:assessments) do
        # CAST is necessary to guarantee correct comparison between datetime and date.
        where('CAST(assessments.created_at AS DATE) BETWEEN DATE_ADD(last_date_of_exposure, INTERVAL 7 DAY) '\
              'AND DATE_ADD(last_date_of_exposure, INTERVAL 9 DAY)')
      end
      .where('? >= DATE_ADD(last_date_of_exposure, INTERVAL 7 DAY)', user_curr_datetime.to_date)
      .where_assoc_exists(:laboratories) do
        where(result: 'negative', lab_type: %w[PCR ANTIGEN])
          .where('specimen_collection BETWEEN DATE_ADD(last_date_of_exposure, INTERVAL 5 DAY) AND DATE_ADD(last_date_of_exposure, INTERVAL 9 DAY)')
      end
  }
  # rubocop:enable Style/MultilineBlockChain

  # Patients in the exposure workflow have finished their monitoring period IF:
  # - not in continuous exposure
  #    AND EITHER
  # - last exposure date is on or after (today - 'monitoring_period_days') in patient local time
  #    OR
  # - last exposure date is null and created date is on or after (today - 'monitoring_period_days') in patient local time
  scope :end_of_monitoring_period, lambda {
    where(continuous_exposure: false)
      .where(
        '('\
        '  patients.last_date_of_exposure IS NOT NULL AND '\
        '  DATE_ADD(patients.last_date_of_exposure, INTERVAL ? DAY)'\
        '    <= DATE(CONVERT_TZ(?, "UTC", patients.time_zone))'\
        ') OR ('\
        '  patients.last_date_of_exposure IS NULL AND '\
        '  DATE_ADD(DATE(CONVERT_TZ(patients.created_at, "UTC", patients.time_zone)), INTERVAL ? DAY)'\
        '    <= DATE(CONVERT_TZ(?, "UTC", patients.time_zone))'\
        ')',
        ADMIN_OPTIONS['monitoring_period_days'],
        Time.now.getlocal('-00:00'),
        ADMIN_OPTIONS['monitoring_period_days'],
        Time.now.getlocal('-00:00')
      )
  }

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
  scope :close_eligible, lambda {
    exposure_asymptomatic
      .submitted_assessment_today
      .end_of_monitoring_period
  }

  # Gets the current date in the patient's timezone
  def curr_date_in_timezone
    Time.now.getlocal(address_timezone_offset)
  end

  # Order individuals based on their public health assigned risk assessment
  def self.order_by_risk(asc: true)
    order_by = <<~SQL
      CASE
      WHEN exposure_risk_assessment='High' THEN 0
      WHEN exposure_risk_assessment='Medium' THEN 1
      WHEN exposure_risk_assessment='Low' THEN 2
      WHEN exposure_risk_assessment='No Identified Risk' THEN 3
      WHEN exposure_risk_assessment IS NULL THEN 4
      END
    SQL

    order_by_rev = <<~SQL
      CASE
      WHEN exposure_risk_assessment IS NULL THEN 4
      WHEN exposure_risk_assessment='High' THEN 3
      WHEN exposure_risk_assessment='Medium' THEN 2
      WHEN exposure_risk_assessment='Low' THEN 1
      WHEN exposure_risk_assessment='No Identified Risk' THEN 0
      END
    SQL
    order(Arel.sql(asc ? order_by : order_by_rev))
  end

  # Check for potential duplicate records. Duplicate criteria is as follows:
  # - matching values of first name and last name. Optionally sex and DoB can also match for more detailed messaging
  # e.g. Jon Smith M null would be a duplicate of Jon Smith M 1/1/2000
  # OR
  # - matching state/local id
  def self.duplicate_data(first_name, last_name, sex, date_of_birth, user_defined_id_statelocal)
    # Track which matches have occurred
    duplicate_field_data = []

    # check for a duplicate state/local id
    dup_statelocal_id = where('user_defined_id_statelocal = ?', user_defined_id_statelocal&.to_s&.strip)
    duplicate_field_data << { count: dup_statelocal_id.count, fields: ['State/Local ID'] } if dup_statelocal_id.present?

    # if first_name or last_name is null skip duplicate detection
    return { is_duplicate: duplicate_field_data.length.positive?, duplicate_field_data: duplicate_field_data } if first_name.nil? || last_name.nil?

    # Get fields that have matching values
    fn_ln_match = where('first_name = ?', first_name)
                  .where('last_name = ?', last_name)

    # count the remaining matches
    remaining_matches = fn_ln_match.count

    # check for all 4 fields matching
    if !date_of_birth.nil? && !sex.nil? && fn_ln_match.present?
      all_match = fn_ln_match.where('date_of_birth = ?', date_of_birth)
                             .where('sex = ?', sex)
      remaining_matches -= all_match.count
      duplicate_field_data << { count: all_match.count, fields: ['First Name', 'Last Name', 'Sex', 'Date of Birth'] } if all_match.present?
    end

    # check for FN LN and S matches
    if !sex.nil? && fn_ln_match.present?
      # if there is a DoB we only want to match with records that do not match the DoB or where the DoB is nil
      fn_ln_s_match = if !date_of_birth.nil?
                        fn_ln_match.where('sex = ?', sex)
                                   .where.not('date_of_birth = ?', date_of_birth)
                                   .or(fn_ln_match.where('sex = ?', sex).where(date_of_birth: nil))
                      else
                        fn_ln_match.where('sex = ?', sex)
                      end
      remaining_matches -= fn_ln_s_match.count
      duplicate_field_data << { count: fn_ln_s_match.count, fields: ['First Name', 'Last Name', 'Sex'] } if fn_ln_s_match.present?

    end

    # check for FN LN and DoB matches
    if !date_of_birth.nil? && fn_ln_match.present?
      # if there is a sex we only want to match with records that do not match the sex or where the sex is nil
      fn_ln_dob_match = if !sex.nil?
                          fn_ln_match.where('date_of_birth = ?', date_of_birth)
                                     .where.not('sex = ?', sex)
                                     .or(fn_ln_match.where('date_of_birth = ?', date_of_birth).where(sex: nil))
                        else
                          fn_ln_match.where('date_of_birth = ?', date_of_birth)
                        end
      remaining_matches -= fn_ln_dob_match.count
      duplicate_field_data << { count: fn_ln_dob_match.count, fields: ['First Name', 'Last Name', 'Date of Birth'] } if fn_ln_dob_match.present?

    end
    # put the remaining matches in
    duplicate_field_data << { count: remaining_matches, fields: ['First Name', 'Last Name'] } if remaining_matches.positive?

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

  # Get this patient's household members including itself
  def household
    responder&.dependents
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    return 'Continuous Exposure' if continuous_exposure
    return (last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s if last_date_of_exposure.present?

    # Check for created_at is necessary here because custom as_json is automatically called when enrolling a new patient, which calls this method indirectly.
    return (created_at.to_date + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s if created_at.present?
  end

  # Date when patient is expected to be purged (without any formatting)
  def expected_purge_ts
    monitoring ? nil : (updated_at + ADMIN_OPTIONS['purgeable_after'].minutes)
  end

  # Date when patient is expected to be purged (with timezone displayed as '+00:00')
  def expected_purge_date
    expected_purge_ts&.rfc2822 || ''
  end

  # Date when patient is expected to be purged (with timezone displayed as 'UTC' for export)
  def expected_purge_date_exp
    expected_purge_ts&.strftime('%F %T %Z') || ''
  end

  # Determine if this patient's phone number has blocked communication with SaraAlert
  def blocked_sms
    return false if primary_telephone.nil?

    BlockedNumber.exists?(phone_number: primary_telephone)
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

    # Return UNLESS:
    # - in exposure: NOT closed AND within monitoring period OR
    # - in isolation: NOT closed (as patients on RRR linelist should receive notifications) OR
    # - in continuous exposure OR
    # - is a HoH with actively monitored dependents
    # NOTE: We do not close out folks on the non-reporting line list in exposure (therefore monitoring will still be true for them),
    # so we also have to check that someone receiving messages is not past they're monitoring period unless they're  in isolation,
    # continuous exposure, or have active dependents.
    start_of_exposure = last_date_of_exposure || created_at
    return unless (monitoring && start_of_exposure >= ADMIN_OPTIONS['monitoring_period_days'].days.ago.beginning_of_day) ||
                  (monitoring && isolation) ||
                  (monitoring && continuous_exposure) ||
                  active_dependents_exclude_self.exists?

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
        # Default to afternoon if preferred contact time is not specified
        return unless (12..16).include? hour
      end
    end

    # Check last_assessment_reminder_sent before enqueueing to cover potential race condition of multiple reports
    # being sent out for the same monitoree.
    return unless last_assessment_reminder_sent_eligible? || send_now

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
    report_cutoff_time = Time.now.getlocal('-04:00').beginning_of_day
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
    patient_as_fhir(self)
  end

  # Override as_json to include linelist
  def as_json(options = {})
    super((options || {}).merge(methods: :linelist))
  end

  def address_timezone_offset
    if monitored_address_state.present?
      time_zone_offset_for_state(monitored_address_state)
    elsif address_state.present?
      time_zone_offset_for_state(address_state)
    else
      time_zone_offset_for_state('massachusetts')
    end
  end

  # Check last_assessment_reminder_sent for eligibility. This is chiefly intended to help cover potential race condition of
  # multiple reports being sent out for the same monitoree.
  def last_assessment_reminder_sent_eligible?
    last_assessment_reminder_sent.nil? || last_assessment_reminder_sent <= 12.hours.ago
  end

  # Callback to set the `time_zone` attribute of the patient.
  # `time_zone` is saved to the DB so that time zone calculations may be done
  # on patient records without needing to load them into rails.
  def set_time_zone
    self.time_zone = if monitored_address_state.present?
                       time_zone_for_state(monitored_address_state)
                     elsif address_state.present?
                       time_zone_for_state(address_state)
                     else
                       time_zone_for_state('massachusetts')
                     end
  end

  # Creates a diff between a patient before and after updates, and creates a detailed record edit History item with the changes.
  def self.detailed_history_edit(patient_before, patient_after, attributes, history_creator_label, is_api_edit: false)
    diffs = patient_diff(patient_before, patient_after, attributes)
    return if diffs.length.zero?

    pretty_diff = diffs.collect { |d| "#{d[:attribute].to_s.humanize} (\"#{d[:before]}\" to \"#{d[:after]}\")" }
    comment = is_api_edit ? 'Monitoree record edited via API. ' : 'User edited a monitoree record. '
    comment += "Changes were: #{pretty_diff.join(', ')}."

    History.record_edit(patient: patient_after, created_by: history_creator_label, comment: comment)
  end

  # Construct a diff for a patient update to keep track of changes
  def self.patient_diff(patient_before, patient_after, attributes)
    diffs = []
    attributes&.each do |attribute|
      # Skip if no value change
      next if patient_before[attribute] == patient_after[attribute]

      diffs << {
        attribute: attribute,
        before: attribute.to_sym == :jurisdiction_id ? Jurisdiction.find(patient_before[attribute])[:path] : patient_before[attribute],
        after: attribute.to_sym == :jurisdiction_id ? Jurisdiction.find(patient_after[attribute])[:path] : patient_after[attribute]
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
    Patient.find(initial_responder).refresh_head_of_household if !initial_responder.nil? && initial_responder != responder.id
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

  # Handle side effect updates to fields that happen whenever certain fields are updated.
  def handle_update
    monitoring_change if monitoring_changed?
    isolation_change if isolation_changed?
    case_status_change if case_status_changed?
    symptom_onset_change if symptom_onset_changed?
    continuous_exposure_change if continuous_exposure_changed?
  end

  # Handle side effects to monitoring being set to false.
  # * closed_at is set to now, since the record is closed.
  # * continuous_exposure is not allowed to be true if the Patient is not monitoring.
  def monitoring_change
    return if monitoring

    self.closed_at = DateTime.now
    self.continuous_exposure = false
  end

  # Handle side effects to isolation being set to false.
  # * extended_isolation is set to nil, since the Patient is being moves to exposure workflow.
  # * symptom_onset is set to a calculated value based on the assessments of the Patient, so they
  #   may be placed in the proper linelist in exposure workflow.
  # * user_defined_symptom_onset is set to false, since the calculated value is being used.
  def isolation_change
    return if isolation

    self.extended_isolation = nil
    # NOTE: The below will overwrite any new value they may set for symptom onset as they can not be set in the exposure workflow.
    self.user_defined_symptom_onset = false
    self.symptom_onset = calculated_symptom_onset(self)
  end

  # Handle side effects to a change in case status.
  # * public_health_action is set to 'None' when case_status changes to 'Suspect', 'Unknown', or 'Not a Case' so
  #   that the Patient will be on the appropriate linelist in the exposure workflow.
  def case_status_change
    return unless ['Suspect', 'Unknown', 'Not a Case'].include?(case_status) && public_health_action != 'None'

    self.public_health_action = 'None'
  end

  # Handle side effects to symptom_onset being set to nil.
  # * symptom_onset is set to a calculated value based on the assessments of the Patient.
  # * user_defined_symptom_onset is set to false, since the calculated value is being used.
  def symptom_onset_change
    return unless symptom_onset.nil?

    self.user_defined_symptom_onset = false
    self.symptom_onset = calculated_symptom_onset(self)
  end

  # Handle side effects to continuous_exposure being set while not monitoring
  # * continuous_exposure should alwasy remain false when not monitoring
  def continuous_exposure_change
    self.continuous_exposure = false if continuous_exposure && !monitoring
  end

  # Create History items corresponding to updates to monitoring fields.
  # The History items detail direct edits, and side effects of those direct edits that are made by the Sara Alert System.
  # These side effects are handled in the handle_update function
  def monitoring_history_edit(history_data, diff_state)
    patient_before = history_data[:patient_before]
    # NOTE: Attributes are sorted so that:
    # - case_status always comes before isolation, since a case_status change may trigger an isolation change from the front end
    # - continuous_exposure comes before last_date_of_exposure, since a continuous_exposure change may trigger an lde change from the front end
    attribute_order = %i[case_status isolation continuous_exposure last_date_of_exposure]
    history_data[:updates].keys.sort_by { |key| attribute_order.index(key) || Float::INFINITY }&.each do |attribute|
      updated_value = self[attribute]
      next if patient_before[attribute] == updated_value

      case attribute
      when :monitoring
        History.monitoring_status(history_data)

        # If the record was in continuous exposure and then it was closed and continuous exposure was turned off
        if !updated_value && patient_before[:continuous_exposure] && !continuous_exposure
          History.monitoring_change(
            patient: self,
            created_by: 'Sara Alert System',
            comment: 'System turned off Continuous Exposure because the record was moved to the closed line list.'
          )
        end
      when :exposure_risk_assessment
        History.exposure_risk_assessment(history_data)
      when :monitoring_plan
        History.monitoring_plan(history_data)
      when :public_health_action
        History.public_health_action(history_data)
      when :assigned_user
        History.assigned_user(history_data)
      when :pause_notifications
        History.pause_notifications(history_data)
      when :last_date_of_exposure
        History.last_date_of_exposure(history_data)
      when :extended_isolation
        History.extended_isolation(history_data)
      when :continuous_exposure
        History.continuous_exposure(history_data)
      when :isolation
        update_patient_history_for_isolation(patient_before, updated_value)
      when :symptom_onset
        History.symptom_onset(history_data)
      when :case_status
        History.case_status(history_data, diff_state)

        # If Case Status was updated to one of the values meant for the Exposure workflow and the Public Health Action was reset.
        if ['Suspect', 'Unknown', 'Not a Case'].include?(updated_value) && patient_before[:public_health_action] != 'None' && public_health_action == 'None'
          message = monitoring ?
          "System changed Latest Public Health Action from \"#{patient_before[:public_health_action]}\" to \"None\" so that the monitoree will appear on
          the appropriate line list in the exposure workflow to continue monitoring." : "System changed Latest Public Health Action
          from \"#{patient_before[:public_health_action]}\" to \"None\"."
          History.monitoring_change(patient: self, created_by: 'Sara Alert System', comment: message)
        end
      when :jurisdiction_id
        History.jurisdiction(history_data)
      end
    end
  end

  def update_patient_history_for_isolation(patient_before, new_isolation_value)
    return if new_isolation_value

    # If moved from Isolation workflow to Exposure workflow and Extended Isolation was cleared
    if !patient_before[:extended_isolation].nil? && extended_isolation.nil?
      History.monitoring_change(
        patient: self,
        created_by: 'Sara Alert System',
        comment: 'System cleared Extended Isolation Date because monitoree was moved from isolation to exposure workflow.'
      )
    end

    # If moved from Isolation worklflow to Exposure and symptom onset had to be cleared
    return unless patient_before[:symptom_onset].nil? != symptom_onset

    comment = if !patient_before[:symptom_onset].nil? && !symptom_onset.nil?
                "System changed Symptom Onset Date from #{patient_before[:symptom_onset].strftime('%m/%d/%Y')} to #{symptom_onset.strftime('%m/%d/%Y')}
                because monitoree was moved from isolation to exposure workflow. This allows the system to show monitoree on appropriate line list based on
                daily reports."
              elsif patient_before[:symptom_onset].nil? && !symptom_onset.nil?
                "System changed Symptom Onset Date from blank to #{symptom_onset.strftime('%m/%d/%Y')} because monitoree was moved from isolation to
                exposure workflow. This allows the system to show monitoree on appropriate line list based on daily reports."
              elsif !patient_before[:symptom_onset].nil? && symptom_onset.nil?
                "System cleared Symptom Onset Date from #{patient_before[:symptom_onset].strftime('%m/%d/%Y')} to blank because monitoree was moved from
                isolation to exposure workflow. This allows the system to show monitoree on appropriate line list based on daily reports."
              else
                'System changed Symptom Onset Date. This allows the system to show monitoree on appropriate line list based on daily reports.'
              end
    History.monitoring_change(patient: self, created_by: 'Sara Alert System', comment: comment)
  end
end
# rubocop:enable Metrics/ClassLength
