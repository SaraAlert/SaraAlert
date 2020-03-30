# frozen_string_literal: true

# Patient: patient model
class Patient < ApplicationRecord
  # TODO: Stricter validation for fields that are handed to other systems (e.g. phone, email address)
  # TODO: Also add guards on what gets handed to external server (only allow specific validated)
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
                                                  nil, ''] }

  validates :monitoring_plan, inclusion: { in: ['Daily active monitoring',
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
                                                     'Referral for Medical Evaluation',
                                                     'Document Completed Medical Evaluation',
                                                     'Document Medical Evaluation Summary and Plan',
                                                     'Referral for Public Health Test',
                                                     'Public Health Test Specimen Received by Lab - results pending',
                                                     'Results of Public Health Test - positive',
                                                     'Results of Public Health Test - negative'] }

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
    where('last_date_of_exposure > ?', time_frame)
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
                "WHEN exposure_risk_assessment='No Identified Risk' THEN 3"]
    order_by_rev = ["WHEN exposure_risk_assessment='High' THEN 3",
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
    Patient.symptomatic.where(id: id).count.positive?
  end

  # Is this patient symptomatic?
  def asymptomatic?
    Patient.asymptomatic.where(id: id).count.positive?
  end

  # Is this patient non_reporting?
  def non_reporting?
    Patient.non_reporting.where(id: id).count.positive?
  end

  # Is this patient under investigation?
  def pui?
    Patient.under_investigation.where(id: id).count.positive?
  end

  # Has this patient purged?
  def purged?
    Patient.purged.where(id: id).count.positive?
  end

  # Has this patient purged?
  def closed?
    Patient.monitoring_closed_without_purged.where(id: id).count.positive?
  end

  # Current patient status
  def status
    return :symptomatic if symptomatic?
    return :asymptomatic if asymptomatic?
    return :non_reporting if non_reporting?
    return :pui if pui?
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
      transferred_from: latest_transfer&.from_path || '',
      transferred_to: latest_transfer&.to_path || ''
    }
  end

  # Override as_json to include linelist
  def as_json(options = {})
    super((options || {}).merge(methods: :linelist))
  end

  # rubocop:todo Metrics/PerceivedComplexity
  def send_assessment(force = false) # rubocop:todo Metrics/CyclomaticComplexity
    unless last_assessment_reminder_sent.nil?
      return if last_assessment_reminder_sent < 24.hours.ago
    end

    # If force is set, the preferred contact time will be ignored
    unless force
      hour = Time.now.hour
      # These are the hours that we consider to be morning, afternoon and evening
      morning = (7..11)
      afternoon = (12..16)
      evening = (17..20)
      if preferred_contact_time == 'Morning'
        return unless morning.include? hour
      elsif preferred_contact_time == 'Afternoon'
        return unless afternoon.include? hour
      elsif preferred_contact_time == 'Evening'
        return unless evening.include? hour
      end
    end

    if preferred_contact_method == 'E-mailed Web Link'
      PatientMailer.assessment_email(self).deliver_later if ADMIN_OPTIONS['enable_email']
    elsif preferred_contact_method == 'SMS Text-message' && responder.id == id && !force
      # SMS-based assessments assess the patient _and_ all of their dependents
      # If you are a dependent ie: someone whose responder.id is not your own  an assessment will not be sent to you
      # Because Twilio will open a second SMS flow for this user and send two responses, this option cannot be forced
      # TODO: Find a way to end existing flows/sessions with this patient, and then this option can be forced
      PatientMailer.assessment_sms(self).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test
    elsif preferred_contact_method == 'SMS Texted Weblink'
      PatientMailer.assessment_sms_weblink(self).deliver_later if ADMIN_OPTIONS['enable_sms'] && !Rails.env.test
    elsif preferred_contact_method == 'Telephone call'
      PatientMailer.assessment_voice(self).deliver_later if ADMIN_OPTIONS['enable_voice'] && !Rails.env.test
    end
    
    last_assessment_reminder_sent = Time.now
    save
  end
  # rubocop:enable Metrics/PerceivedComplexity
end
