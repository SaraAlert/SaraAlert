# frozen_string_literal: true

require 'action_view'
require 'action_view/helpers'

# History: history model
class History < ApplicationRecord
  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 2000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  validates :history_type, inclusion: { in: ['Report Created',
                                             'Report Updated',
                                             'Comment',
                                             'Enrollment',
                                             'Monitoring Change',
                                             'Monitoree Data Downloaded',
                                             'Reports Reviewed',
                                             'Report Reviewed',
                                             'Report Reminder',
                                             'Report Note',
                                             'Lab Result',
                                             'Lab Result Edit',
                                             'Contact Attempt'] }

  belongs_to :patient

  # All histories within the given time frame
  scope :in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('histories.created_at >= ?', 24.hours.ago)
    when 'Last 14 Days'
      where('histories.created_at >= ? AND histories.created_at < ?', 14.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Total'
      all
    else
      none
    end
  }

  # Information about this history
  def details
    {
      patient_id: patient_id || '',
      comment: comment || '',
      created_by: created_by || '',
      history_type: history_type || '',
      history_created_at: created_at || '',
      history_updated_at: updated_at || ''
    }
  end
end
