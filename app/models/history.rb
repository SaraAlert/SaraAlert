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
                                             'Contact Attempt',
                                             'Welcome Message Sent',
                                             'Record Automatically Closed'] }

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

  def self.report_created(patient: nil, created_by: 'Sara Alert System', comment: 'User created a new report.')
    create_history(patient, created_by, 'Report Created', comment)
  end

  def self.report_updated(patient: nil, created_by: 'Sara Alert System', comment: 'User updated existing report.')
    create_history(patient, created_by, 'Report Updated', comment)
  end

  def self.enrollment(patient: nil, created_by: 'Sara Alert System', comment: 'User enrolled monitoree.')
    create_history(patient, created_by, 'Enrollment', comment)
  end

  def self.monitoring_change(patient: nil, created_by: 'Sara Alert System', comment: 'User updated monitoree.')
    create_history(patient, created_by, 'Monitoring Change', comment)
  end

  def self.monitoree_data_downloaded(patient: nil, created_by: 'Sara Alert System', comment: 'User downloaded monitoree\'s data in Excel Export.')
    create_history(patient, created_by, 'Monitoree Data Downloaded', comment)
  end

  def self.reports_reviewed(patient: nil, created_by: 'Sara Alert System', comment: 'User reviewed all reports.')
    create_history(patient, created_by, 'Reports Reviewed', comment)
  end

  def self.report_reviewed(patient: nil, created_by: 'Sara Alert System', comment: 'User reviewed a report.')
    create_history(patient, created_by, 'Report Reviewed', comment)
  end

  def self.report_reminder(patient: nil, created_by: 'Sara Alert System', comment: 'User sent a report reminder to the monitoree.')
    create_history(patient, created_by, 'Report Reminder', comment) unless patient&.preferred_contact_method.nil?
  end

  def self.lab_result(patient: nil, created_by: 'Sara Alert System', comment: 'User added a new lab result.')
    create_history(patient, created_by, 'Lab Result', comment)
  end

  def self.lab_result_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a lab result.')
    create_history(patient, created_by, 'Lab Result Edit', comment)
  end

  def self.contact_attempt(patient: nil, created_by: 'Sara Alert System', comment: 'The system attempted to make contact with the monitoree.')
    create_history(patient, created_by, 'Contact Attempt', comment)
  end

  def self.welcome_message_sent(patient: nil, created_by: 'Sara Alert System', comment: 'Initial Sara Alert welcome message was sent.')
    create_history(patient, created_by, 'Welcome Message Sent', comment)
  end

  def self.record_automatically_closed(patient: nil, created_by: 'Sara Alert System', comment: 'Monitoree has completed monitoring.')
    create_history(patient, created_by, 'Record Automatically Closed', comment)
  end

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

  private_class_method def self.create_history(patient, created_by, type, comment)
    return if patient.nil?

    History.create!(created_by: created_by, comment: comment, patient: patient, history_type: type)
  end
end
