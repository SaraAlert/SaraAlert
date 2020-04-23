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
                                             'Report Reviewed',
                                             'Report Reminder',
                                             'Report Note'] }

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

  # All histories that are monitoring changes in which a patient is no longer monitored
  scope :not_monitoring, lambda {
    where('comment LIKE \'%Not Monitoring%\'')
  }

  # All histories that are public health actions for medical evaluation referrals
  scope :referral_for_medical_evaluation, lambda {
    where('comment LIKE \'%Recommended medical evaluation of symptoms%\'')
  }

  # All histories that are public health actions for documenting completed medical evaluations
  scope :document_completed_medical_evaluation, lambda {
    where('comment LIKE \'%Document results of medical evaluation%\'')
  }

  # All histories that are public health actions for documenting medical evaluation summaries and plans
  scope :document_medical_evaluation_summary_and_plan, lambda {
    where('comment LIKE \'%Laboratory specimen collected%\'')
  }

  # All histories that are public health actions for public health test referrals
  scope :referral_for_public_health_test, lambda {
    where('comment LIKE \'%Recommended laboratory testing%\'')
  }

  # All histories that are public health actions for pending test results
  scope :public_health_test_specimen_received_by_lab_results_pending, lambda {
    where('comment LIKE \'%Laboratory received specimen – result pending%\'')
  }

  # All histories that are public health actions for positive public health test results
  scope :results_of_public_health_test_positive, lambda {
    where('comment LIKE \'%Laboratory report results – positive%\'')
  }

  # All histories that are public health actions for negative public health test results
  scope :results_of_public_health_test_negative, lambda {
    where('comment LIKE \'%Laboratory report results – negative%\'')
  }
end
