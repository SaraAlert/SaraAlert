# frozen_string_literal: true

# Transfer: transfer model
class Transfer < ApplicationRecord
  belongs_to :to_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :from_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :who, class_name: 'User'
  belongs_to :patient

  after_save :update_patient_linelist_after_save
  before_destroy :update_patient_linelist_before_destroy

  def update_patient_linelist_after_save
    latest_transfer_at = patient.transfers.maximum(:created_at)
    latest_transfer = patient.transfers.where(created_at: latest_transfer_at).first
    patient.latest_transfer_at = latest_transfer&.created_at
    patient.latest_transfer_from = latest_transfer&.from_jurisdiction_id
    patient.save
  end

  def update_patient_linelist_before_destroy
    latest_transfer_at = patient.transfers.where.not(id: id).maximum(:created_at)
    latest_transfer = patient.transfers.where.not(id: id).where(created_at: latest_transfer_at).first
    patient.latest_transfer_at = latest_transfer&.created_at
    patient.latest_transfer_from = latest_transfer&.from_jurisdiction_id
    patient.save
  end

  def from_path
    return 'Unknown Jurisdiction' if from_jurisdiction.blank?

    from_jurisdiction[:path] || from_jurisdiction.jurisdiction_path_string
  end

  def to_path
    return 'Unknown Jurisdiction' if to_jurisdiction.blank?

    to_jurisdiction[:path] || to_jurisdiction.jurisdiction_path_string
  end

  # All incoming transfers with the given jurisdiction id
  scope :with_incoming_jurisdiction_id, lambda { |jurisdiction_id|
    where('to_jurisdiction_id = ?', jurisdiction_id)
  }

  # All outgoing transfers with the given jurisdiction id
  scope :with_outgoing_jurisdiction_id, lambda { |jurisdiction_id|
    where('from_jurisdiction_id = ?', jurisdiction_id)
  }

  # All transfers within the given time frame
  scope :in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('transfers.created_at >= ?', 24.hours.ago)
    when 'Last 14 Days'
      where('transfers.created_at >= ? AND transfers.created_at < ?', 14.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Total'
      all
    else
      none
    end
  }
end
