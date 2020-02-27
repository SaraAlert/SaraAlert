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

  # Allow information on the monitoree's jurisdiction to be displayed
  def jurisdiction_path
    jurisdiction&.path&.map(&:name)
  end

  # Single place for calculating the end of monitoring date for this subject.
  def end_of_monitoring
    return last_date_of_exposure + ADMIN_OPTIONS['monitoring_period_days'].days unless last_date_of_exposure.nil?
    return created_at + ADMIN_OPTIONS['monitoring_period_days'].days
  end

end
