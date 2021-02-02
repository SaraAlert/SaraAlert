# frozen_string_literal: true

# Transfer: transfer model
class Transfer < ApplicationRecord
  belongs_to :to_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :from_jurisdiction, class_name: 'Jurisdiction'
  belongs_to :who, class_name: 'User'
  belongs_to :patient

  after_save :update_patient_linelist_after_save
  before_destroy :update_patient_linelist_before_destroy

  def from_path
    return 'Unknown Jurisdiction' if from_jurisdiction.blank?

    from_jurisdiction[:path] || from_jurisdiction.jurisdiction_path_string
  end

  def to_path
    return 'Unknown Jurisdiction' if to_jurisdiction.blank?

    to_jurisdiction[:path] || to_jurisdiction.jurisdiction_path_string
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

  def custom_details(fields, patient_identifiers, user_emails, jurisdiction_paths)
    transfer_details = {}
    transfer_details[:id] = id || '' if fields.include?(:id)
    transfer_details[:patient_id] = patient_id || '' if fields.include?(:patient_id)
    transfer_details[:user_defined_id_statelocal] = patient_identifiers[:user_defined_id_statelocal]
    transfer_details[:user_defined_id_cdc] = patient_identifiers[:user_defined_id_cdc]
    transfer_details[:user_defined_id_nndss] = patient_identifiers[:user_defined_id_nndss]
    transfer_details[:who] = user_emails[who_id] || '' if fields.include?(:who)
    transfer_details[:from_jurisdiction] = jurisdiction_paths[from_jurisdiction_id] || '' if fields.include?(:from_jurisdiction)
    transfer_details[:to_jurisdiction] = jurisdiction_paths[to_jurisdiction_id] || '' if fields.include?(:to_jurisdiction)
    transfer_details[:created_at] = created_at || '' if fields.include?(:created_at)
    transfer_details[:updated_at] = updated_at || '' if fields.include?(:updated_at)
    transfer_details
  end

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
