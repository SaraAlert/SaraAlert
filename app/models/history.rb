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
                                             'Reports Reviewed',
                                             'Report Reminder',
                                             'Report Note'] }

  belongs_to :patient
end
