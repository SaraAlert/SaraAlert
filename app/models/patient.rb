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

  belongs_to :responder, class_name: 'Patient'
  belongs_to :creator, class_name: 'User'
  has_many :dependents, class_name: 'Patient', foreign_key: 'responder_id'
  has_many :assessments
  has_one :latest_assessment, -> { order created_at: :desc }, class_name: 'Assessment'
  belongs_to :jurisdiction
  has_many :histories

  scope :monitoring_open, -> {
    where('monitoring = ?', true)
  }

  scope :monitoring_closed, -> {
    where('monitoring = ?', false)
  }

  scope :symptomatic, -> {
    where('monitoring = ?', true)
    .joins(:assessments)
    .where('assessments.created_at = (SELECT MAX(assessments.created_at) FROM assessments WHERE assessments.patient_id = patients.id)')
    .where('assessments.symptomatic = ?', true)
  }

  scope :non_reporting, -> {
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

  scope :new_subject, -> {
    where('patients.created_at >= ?', ADMIN_OPTIONS['reporting_period_minutes'].minutes.ago)
    .where('monitoring = ?', true)
    .where('id NOT IN (SELECT DISTINCT(patient_id) FROM assessments)')
  }

  scope :asymptomatic, -> {
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

  # Allow information on the monitoree's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    if last_date_of_exposure
      return last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days
    end
    if created_at
      return created_at + ADMIN_OPTIONS['monitoring_period_days'].days
    end
  end

  # Information about this subject (that is useful in a linelist)
  def linelist
    {
      name: {name: "#{last_name}, #{first_name}", id: id},
      jurisdiction: jurisdiction&.name || '',
      state_local_id: user_defined_id_statelocal || '',
      sex: sex || '',
      dob: date_of_birth&.strftime('%F') || '',
      end_of_monitoring: end_of_monitoring&.strftime('%F') || '',
      risk_level: exposure_risk_assessment || '',
      monitoring_plan: monitoring_plan || '',
      latest_report: latest_assessment&.created_at&.strftime('%F') || ''
    }
  end

  # Override as_json to include linelist
  def as_json(options = {})
    super((options || {}).merge(methods: :linelist))
  end

end
