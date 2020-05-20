# frozen_string_literal: true

# Laboratory: represents a lab result
class Laboratory < ApplicationRecord
  belongs_to :patient

  validates :result, inclusion: { in: ['positive', 'negative', 'indeterminate', 'other', nil, ''] }

  scope :last_ten_days_positive, lambda {
    where('report > ?', 10.days.ago).where(result: 'positive')
  }

  scope :before_ten_days_positive, lambda {
    where('report <= ?', 10.days.ago).where(result: 'positive')
  }

  scope :last_ten_days_negative, lambda {
    where('report > ?', 10.days.ago).where(result: 'negative')
  }

  # Information about this laboratory
  def details
    {
      patient_id: patient_id || '',
      lab_type: lab_type || '',
      lab_specimen_collection: specimen_collection || '',
      lab_report: report || '',
      lab_result: result || '',
      lab_created_at: created_at || '',
      lab_updated_at: updated_at || ''
    }
  end
end
