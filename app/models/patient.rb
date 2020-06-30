# frozen_string_literal: true

require 'chronic'

# Patient: patient model
class Patient < ApplicationRecord # rubocop:todo Metrics/ClassLength
  include PatientHelper

  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  validates :monitoring_reason, inclusion: { in: ['Completed Monitoring',
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

  validates :assigned_user, numericality: { only_integer: true, allow_nil: true, greater_than: 0, less_than_or_equal_to: 9999 }

  belongs_to :responder, class_name: 'Patient'
  belongs_to :creator, class_name: 'User'
  has_many :dependents, class_name: 'Patient', foreign_key: 'responder_id'
  has_many :assessments
  belongs_to :jurisdiction
  has_many :histories
  has_many :transfers
  has_many :laboratories

  # Most recent assessment
  def latest_assessment
    assessments.order(created_at: :desc).first
  end

  # Most recent transfer
  def latest_transfer
    transfers.order(created_at: :desc).first
  end

  # Patients who are eligible for reminders (exposure)
  scope :reminder_eligible_exposure, lambda {
    where(isolation: false)
      .where(pause_notifications: false)
      .where('patients.id = patients.responder_id')
      .where(purged: false)
      .where.not(id: Patient.unscoped.exposure_under_investigation)
      .where('last_date_of_exposure >= ? OR continuous_exposure = ?', ADMIN_OPTIONS['monitoring_period_days'].days.ago, true)
      .left_outer_joins(:assessments)
      .where_assoc_not_exists(:assessments, ['created_at >= ?', Time.now.getlocal('-04:00').beginning_of_day])
      .or(
        where(isolation: false)
          .where(pause_notifications: false)
          .where('patients.id = patients.responder_id')
          .where(purged: false)
          .where.not(id: Patient.unscoped.exposure_under_investigation)
          .where('last_date_of_exposure >= ? OR continuous_exposure = ?', ADMIN_OPTIONS['monitoring_period_days'].days.ago, true)
          .left_outer_joins(:assessments)
          .where(assessments: { patient_id: nil })
      )
      .distinct
  }

  # Patients who are eligible for reminders (isolation)
  scope :reminder_eligible_isolation, lambda {
    where(isolation: true)
      .where(pause_notifications: false)
      .where('patients.id = patients.responder_id')
      .where(purged: false)
      .where.not(id: Patient.unscoped.isolation_requiring_review)
      .where.not(id: Patient.unscoped.isolation_non_reporting_max)
      .left_outer_joins(:assessments)
      .where_assoc_not_exists(:assessments, ['created_at >= ?', Time.now.getlocal('-04:00').beginning_of_day])
      .or(
        where(isolation: true)
          .where(pause_notifications: false)
          .where('patients.id = patients.responder_id')
          .where(purged: false)
          .where.not(id: Patient.unscoped.isolation_requiring_review)
          .where.not(id: Patient.unscoped.isolation_non_reporting_max)
          .left_outer_joins(:assessments)
          .where(assessments: { patient_id: nil })
      )
      .distinct
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
      .left_outer_joins(:assessments)
      .where('assessments.symptomatic = ?', true)
      .distinct
  }

  # Non reporting asymptomatic individuals (includes patients in both exposure & isolation workflows)
  scope :non_reporting, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(public_health_action: 'None')
      .left_outer_joins(:assessments)
      .where('assessments.patient_id = patients.id')
      .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .where_assoc_not_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(public_health_action: 'None')
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
        .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      )
      .distinct
  }

  # Individuals who have reported recently and are not symptomatic (includes patients in both exposure & isolation workflows)
  scope :asymptomatic, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(public_health_action: 'None')
      .left_outer_joins(:assessments)
      .where('assessments.patient_id = patients.id')
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .where_assoc_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(public_health_action: 'None')
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
        .where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      )
      .distinct
  }

  # Any individual who has any assessments still considered symptomatic (exposure workflow only)
  scope :exposure_symptomatic, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: false)
      .where(public_health_action: 'None')
      .left_outer_joins(:assessments)
      .where('assessments.symptomatic = ?', true)
      .distinct
  }

  # Non reporting asymptomatic individuals (exposure workflow only)
  scope :exposure_non_reporting, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: false)
      .where(public_health_action: 'None')
      .left_outer_joins(:assessments)
      .where('assessments.patient_id = patients.id')
      .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .where_assoc_not_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: false)
        .where(public_health_action: 'None')
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
        .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      )
      .distinct
  }

  # Individuals who have reported recently and are not symptomatic (exposure workflow only)
  scope :exposure_asymptomatic, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: false)
      .where(public_health_action: 'None')
      .left_outer_joins(:assessments)
      .where('assessments.patient_id = patients.id')
      .where_assoc_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
      .where_assoc_not_exists(:assessments, symptomatic: true)
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: false)
        .where(public_health_action: 'None')
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
        .where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      )
      .distinct
  }

  # Any individual who is currently under investigation (exposure workflow only)
  scope :exposure_under_investigation, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: false)
      .where.not(public_health_action: 'None')
  }

  # Individuals that meet the test based review requirement (isolation workflow only)
  scope :isolation_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where_assoc_exists(:assessments)
      .where_assoc_not_exists(:assessments, &:twenty_four_hours_fever_or_fever_medication)
      .where_assoc_count(2, :<=, :laboratories, 'result = "negative"')
      .distinct
  }

  # Individuals that meet the symptomatic non test based review requirement (isolation workflow only)
  scope :isolation_symp_non_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where_assoc_exists(:assessments, &:older_than_seventy_two_hours)
      .where_assoc_not_exists(:assessments, &:seventy_two_hours_fever_or_fever_medication)
      .where('symptom_onset <= ?', 10.days.ago)
      .distinct
  }

  # Individuals that meet the asymptomatic recovery definition (isolation workflow only)
  scope :isolation_asymp_non_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where_assoc_exists(:laboratories, &:before_ten_days_positive)
      .where_assoc_not_exists(:laboratories, &:last_ten_days_positive)
      .where_assoc_exists(:assessments)
      .where_assoc_not_exists(:assessments, &:symptomatic)
      .distinct
  }

  # Individuals in the isolation workflow that require review (isolation workflow only)
  scope :isolation_requiring_review, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where_assoc_exists(:assessments)
      .where_assoc_not_exists(:assessments, &:twenty_four_hours_fever_or_fever_medication)
      .where_assoc_count(2, :<=, :laboratories, 'result = "negative"')
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: true)
        .where_assoc_exists(:assessments, &:older_than_seventy_two_hours)
        .where_assoc_not_exists(:assessments, &:seventy_two_hours_fever_or_fever_medication)
        .where('symptom_onset <= ?', 10.days.ago)
      )
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: true)
        .where_assoc_exists(:laboratories, &:before_ten_days_positive)
        .where_assoc_not_exists(:laboratories, &:last_ten_days_positive)
        .where_assoc_exists(:assessments)
        .where_assoc_not_exists(:assessments, &:symptomatic)
      )
      .distinct
  }

  # Individuals not meeting review and are not reporting (isolation workflow only)
  scope :isolation_non_reporting, lambda {
    where.not(id: Patient.unscoped.isolation_requiring_review)
         .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
         .where(monitoring: true)
         .where(purged: false)
         .where(isolation: true)
         .where_assoc_not_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
         .distinct
  }

  # Individuals not meeting review and are not reporting for a while (isolation workflow only)
  scope :isolation_non_reporting_max, lambda {
    where.not(id: Patient.unscoped.isolation_requiring_review)
         .where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
         .where(monitoring: true)
         .where(purged: false)
         .where(isolation: true)
         .where_assoc_not_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['isolation_non_reporting_max_days'].days.ago])
         .distinct
  }

  # Individuals not meeting review but are reporting (isolation workflow only)
  scope :isolation_reporting, lambda {
    where.not(id: Patient.unscoped.isolation_requiring_review)
         .where(monitoring: true)
         .where(purged: false)
         .where(isolation: true)
         .left_outer_joins(:assessments)
         .where_assoc_exists(:assessments, ['created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
         .or(
           where.not(id: Patient.unscoped.isolation_requiring_review)
             .where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
             .where(monitoring: true)
             .where(purged: false)
             .where(isolation: true)
             .left_outer_joins(:assessments)
             .where(assessments: { patient_id: nil })
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
  def self.matches(first_name, last_name, sex, date_of_birth, user_defined_id_statelocal)
    where('first_name = ?', first_name)
      .where('last_name = ?', last_name)
      .where('sex = ?', sex)
      .where('date_of_birth = ?', date_of_birth)
      .or(
        where('user_defined_id_statelocal = ?', user_defined_id_statelocal&.to_s&.strip)
      )
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

  # Allow information on the monitoree's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    return (last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s if last_date_of_exposure.present?
    return (created_at + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s if created_at.present?
  end

  # Is this patient symptomatic?
  def symptomatic?
    assessments.where(symptomatic: true).exists?
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
    return :purged if purged?
    return :closed if closed?

    unless isolation
      return :exposure_under_investigation if pui?
      return :exposure_symptomatic if symptomatic?
      return :exposure_asymptomatic if asymptomatic?

      return :exposure_non_reporting
    end
    return :isolation_asymp_non_test_based if Patient.where(id: id).isolation_asymp_non_test_based.exists?
    return :isolation_symp_non_test_based if Patient.where(id: id).isolation_symp_non_test_based.exists?
    return :isolation_test_based if Patient.where(id: id).isolation_test_based.exists?
    return :isolation_reporting if Patient.where(id: id).isolation_reporting.exists?

    :isolation_non_reporting
  end

  # Updated symptom onset date IF updated assessment happens to be the oldest symptomatic
  def refresh_symptom_onset(assessment_id)
    assessment = assessments.where(symptomatic: true).order(:created_at).limit(1)&.first
    return unless !assessment.nil? && !assessment_id.blank? && assessment.id == assessment_id
    return if !symptom_onset.nil? && !assessment.nil? && symptom_onset < assessment.created_at

    update(symptom_onset: assessment&.created_at&.to_date) unless assessment.nil?
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

  def send_assessment(force = false)
    return if ['Unknown', 'Opt-out', '', nil].include?(preferred_contact_method)

    unless last_assessment_reminder_sent.nil?
      return if last_assessment_reminder_sent > 12.hours.ago
    end

    # Do not allow messages to go to household members
    return unless responder.id == id

    # Return if closed, UNLESS there are still group members who need to be reported on
    return unless monitoring || dependents.where(monitoring: true).count.positive?

    # If force is set, the preferred contact time will be ignored
    unless force
      hour = Time.now.getlocal(address_timezone_offset).hour
      # These are the hours that we consider to be morning, afternoon and evening
      morning = (8..11)
      afternoon = (12..15)
      evening = (16..19)
      if preferred_contact_time == 'Morning'
        return unless morning.include? hour
      elsif preferred_contact_time == 'Afternoon'
        return unless afternoon.include? hour
      elsif preferred_contact_time == 'Evening'
        return unless evening.include? hour
      end
    end

    # Default calling to afternoon if not specified
    if preferred_contact_method&.downcase == 'telephone call' && responder.id == id && preferred_contact_time.blank?
      hour = Time.now.getlocal(address_timezone_offset).hour
      return unless (12..16).include? hour
    end

    if preferred_contact_method&.downcase == 'sms text-message' && responder.id == id && ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
      # SMS-based assessments assess the patient _and_ all of their dependents
      # If you are a dependent ie: someone whose responder.id is not your own an assessment will not be sent to you
      # Because Twilio will open a second SMS flow for this user and send two responses, this option cannot be forced
      # TODO: Find a way to end existing flows/sessions with this patient, and then this option can be forced
      if !force
        PatientMailer.assessment_sms(self).deliver_later
      else
        PatientMailer.assessment_sms_reminder(self).deliver_later
      end
    elsif preferred_contact_method&.downcase == 'sms texted weblink' && responder.id == id
      PatientMailer.assessment_sms_weblink(self).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
    elsif preferred_contact_method&.downcase == 'telephone call' && responder.id == id
      PatientMailer.assessment_voice(self).deliver_later if ADMIN_OPTIONS['enable_voice'] && !Rails.env.test?
    elsif preferred_contact_method&.downcase == 'e-mailed web link' && ADMIN_OPTIONS['enable_email'] && responder.id == id && email.present?
      PatientMailer.assessment_email(self).deliver_later
    end

    update(last_assessment_reminder_sent: DateTime.now)
  end

  def calc_current_age
    dob = date_of_birth || Date.today
    today = Date.today
    age = today.year - dob.year
    age -= 1 if
        (dob.month > today.month) ||
        ((dob.month >= today.month) && (dob.day > today.day))
    age
  end

  def select_language
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    lang = PatientHelper.languages(primary_language)&.dig(:code)&.to_sym || :en
    lang = :en unless %i[en es es-PR so fr].include?(lang)
    lang
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
        to_isolation_extension(isolation)
      ].reject(&:nil?)
    )
  end

  # Create a hash of atttributes that corresponds to a Sara Alert Patient (and can be used to
  # create new ones, or update existing ones), using the given FHIR::Patient.
  def self.from_fhir(patient)
    {
      monitoring: patient&.active.nil? ? false : patient.active,
      first_name: patient&.name&.first&.given&.first,
      middle_name: patient&.name&.first&.given&.second,
      last_name: patient&.name&.first&.family,
      primary_telephone: Phonelib.parse(patient&.telecom&.select { |t| t&.system == 'phone' }&.first&.value, 'US').full_e164,
      secondary_telephone: Phonelib.parse(patient&.telecom&.select { |t| t&.system == 'phone' }&.second&.value, 'US').full_e164,
      email: patient&.telecom&.select { |t| t&.system == 'email' }&.first&.value,
      date_of_birth: patient&.birthDate,
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
      isolation: PatientHelper.from_isolation_extension(patient)
    }
  end

  # Information about this subject (that is useful in a linelist)
  def linelist
    {
      id: id,
      name: first_name.present? || last_name.present? ? "#{last_name}#{first_name.blank? ? '' : ', ' + first_name}" : 'NAME NOT PROVIDED',
      jurisdiction: jurisdiction&.name || '',
      assigned_user: assigned_user || '',
      state_local_id: user_defined_id_statelocal || '',
      sex: sex || '',
      dob: date_of_birth&.strftime('%F') || '',
      end_of_monitoring: (continuous_exposure ? 'Continuous Exposure' : end_of_monitoring) || '',
      risk_level: exposure_risk_assessment || '',
      monitoring_plan: monitoring_plan || '',
      latest_report: latest_assessment&.created_at&.rfc2822 || '',
      transferred: latest_transfer&.created_at&.rfc2822 || '',
      reason_for_closure: monitoring_reason || '',
      public_health_action: public_health_action || '',
      status: status&.to_s&.humanize&.downcase&.gsub('exposure ', '')&.gsub('isolation ', '') || '',
      closed_at: closed_at&.rfc2822 || '',
      transferred_from: latest_transfer&.from_path || '',
      transferred_to: latest_transfer&.to_path || '',
      expected_purge_date: updated_at.nil? ? '' : ((updated_at + ADMIN_OPTIONS['purgeable_after'].minutes)&.rfc2822 || '')
    }
  end

  # All information about this subject
  def comprehensive_details
    labs = Laboratory.where(patient_id: id).order(report: :desc)
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
      status: '',
      symptom_onset: symptom_onset&.strftime('%F') || '',
      case_status: case_status || '',
      lab_1_type: labs[0] ? (labs[0].lab_type || '') : '',
      lab_1_specimen_collection: labs[0] ? (labs[0].specimen_collection&.strftime('%F') || '') : '',
      lab_1_report: labs[0] ? (labs[0].report&.strftime('%F') || '') : '',
      lab_1_result: labs[0] ? (labs[0].result || '') : '',
      lab_2_type: labs[1] ? (labs[1].lab_type || '') : '',
      lab_2_specimen_collection: labs[1] ? (labs[1].specimen_collection&.strftime('%F') || '') : '',
      lab_2_report: labs[1] ? (labs[1].report&.strftime('%F') || '') : '',
      lab_2_result: labs[1] ? (labs[1].result || '') : '',
      jurisdiction_path: jurisdiction[:path] || '',
      assigned_user: assigned_user || ''
    }
  end

  # Override as_json to include linelist
  def as_json(options = {})
    super((options || {}).merge(methods: :linelist))
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
end
