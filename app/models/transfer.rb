# frozen_string_literal: true

# Transfer: transfer model
class Transfer < ApplicationRecord
  belongs_to :to_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :from_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :who, class_name: 'User'
  belongs_to :patient, touch: true

  after_save :update_patient_linelist_after_save
  before_destroy :update_patient_linelist_before_destroy

  def from_path
    return 'Unknown Jurisdiction' if from_jurisdiction.blank?

    from_jurisdiction[:path]
  end

  def to_path
    return 'Unknown Jurisdiction' if to_jurisdiction.blank?

    to_jurisdiction[:path]
  end

  # All transfers within the given time frame
  scope :in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('transfers.created_at >= ?', 24.hours.ago)
    when 'Last 7 Days'
      where('transfers.created_at >= ? AND transfers.created_at < ?', 7.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Last 14 Days'
      where('transfers.created_at >= ? AND transfers.created_at < ?', 14.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Total'
      all
    else
      none
    end
  }

  scope :latest_transfers, lambda { |patients|
    where(
      '(transfers.patient_id, transfers.created_at) IN ('\
      '  SELECT transfers.patient_id, MAX(transfers.created_at)'\
      '  FROM transfers'\
      '  WHERE transfers.patient_id IN (?)'\
      '  GROUP BY transfers.patient_id'\
      ')',
      patients.pluck(:id)
    )
  }

  private

  def update_patient_linelist_after_save
    latest_transfer_at = patient.transfers.maximum(:created_at)
    latest_transfer = patient.transfers.where(created_at: latest_transfer_at).first
    patient.update(
      latest_transfer_at: latest_transfer&.created_at,
      latest_transfer_from: latest_transfer&.from_jurisdiction_id
    )
  end

  def update_patient_linelist_before_destroy
    latest_transfer_at = patient.transfers.where.not(id: id).maximum(:created_at)
    latest_transfer = patient.transfers.where.not(id: id).where(created_at: latest_transfer_at).first
    patient.update(
      latest_transfer_at: latest_transfer&.created_at,
      latest_transfer_from: latest_transfer&.from_jurisdiction_id
    )
  end
end
