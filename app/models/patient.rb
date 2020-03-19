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
      .where_assoc_not_exists(:latest_assessment, ['created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago])
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
  scope :with_active_monitoring, lambda { |active_monitoring|
    where(monitoring: true) if active_monitoring
  }

  # All individuals with the given risk level
  scope :with_risk_level, lambda { |risk_level|
    where(exposure_risk_assessment: nil) if risk_level.nil?
    where(exposure_risk_assessment: risk_level)
  }

  # All individuals with the given filter
  scope :with_filter, lambda { |category_type, category|
    case category_type
    when 'monitoring_status'
      with_monitoring_status(category)
    when 'age_group'
      with_age_group(category)
    when 'sex'
      where(sex: category)
    when 'risk_factor'
      with_risk_factor(category)
    when 'exposure_country'
      where(potential_exposure_country: category)
    when 'last_exposure_date'
      where(last_date_of_exposure: category)
    when 'last_exposure_week'
      where('last_date_of_exposure >= ? AND last_date_of_exposure < ?', category, category + 1.week)
    when 'last_exposure_month'
      where('last_date_of_exposure >= ? AND last_date_of_exposure < ?', category, category + 1.month)
    end
  }

  # All individuals with the given monitoring status
  scope :with_monitoring_status, lambda { |monitoring_status|
    case monitoring_status
    when 'symptomatic'
      symptomatic
    when 'non_reporting'
      non_reporting
    when 'asymptomatic'
      asymptomatic
    end
  }

  # All individuals with the given age group
  scope :with_age_group, lambda { |age_group|
    case age_group
    when '0-19'
      where('date_of_birth > ?', 20.years.ago.to_date)
    when '20-29'
      where('date_of_birth < ? AND date_of_birth >= ?', 20.years.ago.to_date, 30.years.ago.to_date)
    when '30-39'
      where('date_of_birth < ? AND date_of_birth >= ?', 30.years.ago.to_date, 40.years.ago.to_date)
    when '40-49'
      where('date_of_birth < ? AND date_of_birth >= ?', 40.years.ago.to_date, 50.years.ago.to_date)
    when '50-59'
      where('date_of_birth < ? AND date_of_birth >= ?', 50.years.ago.to_date, 60.years.ago.to_date)
    when '60-69'
      where('date_of_birth < ? AND date_of_birth >= ?', 60.years.ago.to_date, 70.years.ago.to_date)
    when '70-79'
      where('date_of_birth < ? AND date_of_birth >= ?', 70.years.ago.to_date, 80.years.ago.to_date)
    when '>=80'
      where('date_of_birth <= ?', 80.years.ago.to_date)
    end
  }

  # All individuals with the given risk factor
  scope :with_risk_factor, lambda { |risk_factor|
    case risk_factor
    when 'Close Contact with Known Case'
      where(contact_of_known_case: true)
    when 'Travel to Affected Country or Area'
      where(travel_to_affected_country_or_area: true)
    when 'Was in Healthcare Facility with Known Cases'
      where(was_in_health_care_facility_with_known_cases: true)
    when 'Healthcare Personnel'
      where(healthcare_personnel: true)
    when 'Common Exposure Cohort'
      where(member_of_a_common_exposure_cohort: true)
    when 'Crew on Passenger or Cargo Flight'
      where(crew_on_passenger_or_cargo_flight: true)
    when 'Laboratory Personnel'
      where(laboratory_personnel: true)
    when 'Total'
      where(contact_of_known_case: true)
      .or(where(travel_to_affected_country_or_area: true))
      .or(where(was_in_health_care_facility_with_known_cases: true))
      .or(where(healthcare_personnel: true))
      .or(where(member_of_a_common_exposure_cohort: true))
      .or(where(crew_on_passenger_or_cargo_flight: true))
      .or(where(laboratory_personnel: true))
    end
  }

  # All individuals with the given exposure country
  scope :with_exposure_country, lambda { |exposure_country|
    where.not(potential_exposure_country: nil) if exposure_country == 'Total'
    where(potential_exposure_country: category)
  }

  # All individuals enrolled within the given time frame
  scope :enrolled_in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('patients.created_at >= ?', 24.hours.ago.to_date)
    when 'Last 14 Days'
      where('patients.created_at >= ? AND patients.created_at < ?', 14.days.ago.to_date, Date.today)
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
end
