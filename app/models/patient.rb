# frozen_string_literal: true

require 'chronic'

# Patient: patient model
class Patient < ApplicationRecord
  include PatientHelper
  include PatientDetailsHelper

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
  has_many :close_contacts

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
      .where('isolation = ? OR last_date_of_exposure >= ? OR continuous_exposure = ?', true, (ADMIN_OPTIONS['monitoring_period_days'] + 1).days.ago, true)
      .where.not('latest_assessment_at >= ?', Time.now.getlocal('-04:00').beginning_of_day)
      .or(
        where(purged: false)
          .where(pause_notifications: false)
          .where('patients.id = patients.responder_id')
          .where('isolation = ? OR last_date_of_exposure >= ? OR continuous_exposure = ?', true, (ADMIN_OPTIONS['monitoring_period_days'] + 1).days.ago, true)
          .where(latest_assessment_at: nil)
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
      .distinct
  }

  # Individuals that meet the symptomatic non test based review requirement (isolation workflow only)
  scope :isolation_symp_non_test_based, lambda {
    where(monitoring: true)
      .where(purged: false)
      .where(isolation: true)
      .where('symptom_onset <= ?', 10.days.ago)
      .where(latest_fever_or_fever_reducer_at: nil)
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: true)
        .where('symptom_onset <= ?', 10.days.ago)
        .where('latest_fever_or_fever_reducer_at < ?', 24.hours.ago)
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
      .or(
        where(monitoring: true)
        .where(purged: false)
        .where(isolation: true)
        .where.not(latest_assessment_at: nil)
        .where('latest_fever_or_fever_reducer_at < ?', 24.hours.ago)
        .where('negative_lab_count >= ?', 2)
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

  # Patient name to be displayed in linelist
  def displayed_name
    first_name.present? || last_name.present? ? "#{last_name}#{first_name.blank? ? '' : ', ' + first_name}" : 'NAME NOT PROVIDED'
  end

  # Allow information on the monitoree's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Get this patient's dependents excluding itself
  def dependents_exclude_self
    dependents.where.not(id: id)
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    return 'Continuous Exposure' if continuous_exposure
    return (last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days)&.to_s if last_date_of_exposure.present?
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

  # Send a daily assessment to this monitoree
  def send_assessment(force = false)
    return if ['Unknown', 'Opt-out', '', nil].include?(preferred_contact_method)

    unless last_assessment_reminder_sent.nil?
      return if last_assessment_reminder_sent > 12.hours.ago
    end

    # Do not allow messages to go to household members
    return unless responder_id == id

    # Return if closed, UNLESS there are still group members who need to be reported on
    return unless monitoring ||
                  continuous_exposure ||
                  dependents.where(monitoring: true).exists? ||
                  dependents.where(continuous_exposure: true).exists?

    # If force is set, the preferred contact time will be ignored
    unless force
      hour = Time.now.getlocal(address_timezone_offset).hour
      # These are the hours that we consider to be morning, afternoon and evening
      morning = (8..12)
      afternoon = (12..16)
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
    if (preferred_contact_method&.downcase == 'telephone call' ||
        preferred_contact_method&.downcase == 'sms texted weblink' ||
        preferred_contact_method&.downcase == 'sms text-message') && responder.id == id && preferred_contact_time.blank?
      hour = Time.now.getlocal(address_timezone_offset).hour
      return unless (11..17).include? hour
    end

    if preferred_contact_method&.downcase == 'sms text-message' && responder.id == id && ADMIN_OPTIONS['enable_sms'] && !Rails.env.test?
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
  end

  # Return the calculated age based on the date of birth
  def calc_current_age
    dob = date_of_birth || Date.today
    today = Date.today
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

    # Can't send messages if notifications are paused
    if pause_notifications
      eligible = false
      messages << { message: 'Monitoree\'s notifications are paused', datetime: nil }
    end

    # Can't send to household members
    if id != responder_id
      eligible = false
      household = true
      messages << { message: 'Monitoree is within a household, so the HoH will receive notifications instead', datetime: nil }
    end

    # Has an ineligible preferred contact method
    if ['Unknown', 'Opt-out', '', nil].include?(preferred_contact_method)
      eligible = false
      messages << { message: "Monitoree has an ineligible preferred contact method (#{preferred_contact_method || 'Missing'})", datetime: nil }
    end

    # Exposure workflow specific conditions
    unless isolation
      # Monitoring period has elapsed
      if (!last_date_of_exposure.nil? && last_date_of_exposure < reporting_period) && !continuous_exposure
        eligible = false
        messages << { message: "Monitoree\'s monitoring period has elapsed and continuous exposure is not enabled", datetime: end_of_monitoring }
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
      messages << if preferred_contact_time == 'Morning'
                    { message: '8:00 AM local time (Morning)', datetime: nil }
                  elsif preferred_contact_time == 'Afternoon'
                    { message: '12:00 PM local time (Afternoon)', datetime: nil }
                  elsif preferred_contact_time == 'Evening'
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
