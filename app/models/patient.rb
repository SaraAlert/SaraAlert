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
  }

  # All individuals non currently being monitored
  scope :monitoring_closed, lambda {
    where('monitoring = ?', false)
  }

  # All individuals who are confirmed cases
  scope :confirmed_case, lambda {
    where('monitoring_reason = ?', 'Case confirmed')
  }

  # Any individual whose latest report was symptomatic
  scope :symptomatic, lambda {
    where('monitoring = ?', true)
      .joins(:assessments)
      .where('assessments.created_at = (SELECT MAX(assessments.created_at) FROM assessments WHERE assessments.patient_id = patients.id)')
      .where('assessments.symptomatic = ?', true)
  }

  # Non reporting asymptomatic individuals
  scope :non_reporting, lambda {
    where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .where('monitoring = ?', true)
      .left_outer_joins(:assessments)
      .where('assessments.created_at = (SELECT MAX(assessments.created_at) FROM assessments WHERE assessments.patient_id = patients.id)')
      .where('assessments.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .where('assessments.symptomatic = ?', false)
      .or(
        where('patients.created_at < ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
        .where('monitoring = ?', true)
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
      )
  }

  # Newly enrolled individuals
  scope :new_subject, lambda {
    where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .where('monitoring = ?', true)
      .where('id NOT IN (SELECT DISTINCT(patient_id) FROM assessments)')
  }

  # Individuals who have reported recently and are not symptomatic
  scope :asymptomatic, lambda {
    where('monitoring = ?', true)
      .left_outer_joins(:assessments)
      .where('assessments.created_at = (SELECT MAX(assessments.created_at) FROM assessments WHERE assessments.patient_id = patients.id)')
      .where('assessments.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
      .where('assessments.symptomatic = ?', false)
      .or(
        where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
        .where('monitoring = ?', true)
        .left_outer_joins(:assessments)
        .where(assessments: { patient_id: nil })
      )
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

  # Allow information on the monitoree's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    return last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days if last_date_of_exposure
    return created_at + ADMIN_OPTIONS['monitoring_period_days'].days if created_at
  end

  # Information about this subject (that is useful in a linelist)
  def linelist
    {
      name: { name: "#{last_name}, #{first_name}", id: id },
      jurisdiction: jurisdiction&.name || '',
      state_local_id: user_defined_id_statelocal || '',
      sex: sex || '',
      dob: date_of_birth&.strftime('%F') || '',
      end_of_monitoring: end_of_monitoring&.strftime('%F') || '',
      risk_level: exposure_risk_assessment || '',
      monitoring_plan: monitoring_plan || '',
      latest_report: latest_assessment&.created_at&.strftime('%F') || '',
      transferred: latest_transfer&.created_at&.to_s || '',
      reason_for_closure: monitoring_reason || ''
    }
  end

  # Override as_json to include linelist
  def as_json(options = {})
    super((options || {}).merge(methods: :linelist))
  end
end
