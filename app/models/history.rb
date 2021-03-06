# frozen_string_literal: true

require 'action_view'
require 'action_view/helpers'

# History: history model
class History < ApplicationRecord
  include ExcelSanitizer

  HISTORY_TYPES = {
    record_edit: 'Record Edit',
    report_created: 'Report Created',
    report_updated: 'Report Updated',
    comment: 'Comment',
    enrollment: 'Enrollment',
    monitoring_change: 'Monitoring Change',
    monitoree_data_downloaded: 'Monitoree Data Downloaded',
    reports_reviewed: 'Reports Reviewed',
    report_reviewed: 'Report Reviewed',
    report_reminder: 'Report Reminder',
    report_note: 'Report Note',
    lab_result: 'Lab Result',
    lab_result_edit: 'Lab Result Edit',
    vaccination: 'Vaccination',
    vaccination_edit: 'Vaccination Edit',
    close_contact: 'Close Contact',
    close_contact_edit: 'Close Contact Edit',
    contact_attempt: 'Contact Attempt',
    welcome_message_sent: 'Welcome Message Sent',
    record_automatically_closed: 'Record Automatically Closed'
  }.freeze

  columns.each do |column|
    case column.type
    when :text
      validates column.name.to_sym, length: { maximum: 10_000 }
    when :string
      validates column.name.to_sym, length: { maximum: 200 }
    end
  end

  validates :history_type, inclusion: { in: HISTORY_TYPES.values }

  belongs_to :patient

  # Patient updated_at should not be updated if history was created by a monitoree data download
  after_create(proc { patient.touch unless history_type == HISTORY_TYPES[:monitoree_data_downloaded] })

  # All histories within the given time frame
  scope :in_time_frame, lambda { |time_frame|
    case time_frame
    when 'Last 24 Hours'
      where('histories.created_at >= ?', 24.hours.ago)
    when 'Last 7 Days'
      where('histories.created_at >= ? AND histories.created_at < ?', 7.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Last 14 Days'
      where('histories.created_at >= ? AND histories.created_at < ?', 14.days.ago.to_date.to_datetime, Date.today.to_datetime)
    when 'Total'
      all
    else
      none
    end
  }

  # Histories created since the given time that are user driven (not system, or enrollment)
  scope :user_generated_since, lambda { |since|
    where('created_at >= ?', since)
      .where.not(created_by: 'Sara Alert System')
      .where.not(history_type: 'Enrollment')
  }

  # Histories created in the last 24 hours that show the system closing a record
  scope :system_closed_last_24h, lambda {
    where('created_at >= ?', 24.hours.ago)
      .where(history_type: HISTORY_TYPES[:record_automatically_closed])
  }

  # Histories created in the last 24 hours that show a user closing a record
  scope :user_closed_last_24h, lambda {
    where('created_at >= ?', 24.hours.ago)
      .where('comment like ?', 'User changed Monitoring Status from "Monitoring" to "Not Monitoring"%')
  }

  # Histories that indicate a record was moved from exposure to isolation
  scope :exposure_to_isolation, lambda {
    where('comment like ?', '%Continue Monitoring in Isolation Workflow%')
  }

  # Histories that indicate a public health action
  scope :changed_public_health_action, lambda {
    where('comment like ?', '%changed Latest Public Health Action from "None" to%')
  }

  # Histories created in the last 24 hours that show a user enrolling a record
  scope :user_enrolled_last_24h, lambda {
    where('created_at >= ?', 24.hours.ago)
      .where(comment: 'User enrolled monitoree.')
  }

  # Histories created in the last 24 hours that show the API enrolling a record
  scope :api_enrolled_last_24h, lambda {
    where('created_at >= ?', 24.hours.ago)
      .where(comment: 'Monitoree enrolled via API.')
  }

  # Histories created since the given date that indicate the system sent a reminder to the monitoree
  scope :reminder_sent_since, lambda { |since|
    where('created_at >= ?', since)
      .where('comment like ?', 'Sara Alert sent a report reminder%')
  }

  # Histories created since the given date that indicate a user reviewed reports
  scope :reports_reviewed_since, lambda { |since|
    where('created_at >= ?', since)
      .where(history_type: [HISTORY_TYPES[:reports_reviewed], HISTORY_TYPES[:report_reviewed]])
  }

  def self.record_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a record.')
    create_history(patient, created_by, HISTORY_TYPES[:record_edit], comment)
  end

  def self.report_created(patient: nil, created_by: 'Sara Alert System', comment: 'User created a new report.')
    create_history(patient, created_by, HISTORY_TYPES[:report_created], comment)
  end

  def self.report_updated(patient: nil, created_by: 'Sara Alert System', comment: 'User updated existing report.')
    create_history(patient, created_by, HISTORY_TYPES[:report_updated], comment)
  end

  def self.enrollment(patient: nil, created_by: 'Sara Alert System', comment: 'User enrolled monitoree.')
    create_history(patient, created_by, HISTORY_TYPES[:enrollment], comment)
  end

  def self.monitoring_change(patient: nil, created_by: 'Sara Alert System', comment: 'User updated monitoree.')
    create_history(patient, created_by, HISTORY_TYPES[:monitoring_change], comment)
  end

  def self.monitoree_data_downloaded(patient: nil, created_by: 'Sara Alert System', comment: 'User downloaded monitoree\'s data in Excel Export.')
    create_history(patient, created_by, HISTORY_TYPES[:monitoree_data_downloaded], comment)
  end

  def self.reports_reviewed(patient: nil, created_by: 'Sara Alert System', comment: 'User reviewed all reports.')
    create_history(patient, created_by, HISTORY_TYPES[:reports_reviewed], comment)
  end

  def self.report_reviewed(patient: nil, created_by: 'Sara Alert System', comment: 'User reviewed a report.')
    create_history(patient, created_by, HISTORY_TYPES[:report_reviewed], comment)
  end

  def self.report_reminder(patient: nil, created_by: 'Sara Alert System', comment: 'User sent a report reminder to the monitoree.')
    create_history(patient, created_by, HISTORY_TYPES[:report_reminder], comment) unless patient&.preferred_contact_method.nil?
  end

  def self.vaccination(patient: nil, created_by: 'Sara Alert System', comment: 'User added a new vaccination.')
    create_history(patient, created_by, HISTORY_TYPES[:vaccination], comment)
  end

  def self.vaccination_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a vaccination.')
    create_history(patient, created_by, HISTORY_TYPES[:vaccination_edit], comment)
  end

  def self.lab_result(patient: nil, created_by: 'Sara Alert System', comment: 'User added a new lab result.')
    create_history(patient, created_by, HISTORY_TYPES[:lab_result], comment)
  end

  def self.lab_result_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a lab result.')
    create_history(patient, created_by, HISTORY_TYPES[:lab_result_edit], comment)
  end

  def self.close_contact(patient: nil, created_by: 'Sara Alert System', comment: 'User added a new close contact.')
    create_history(patient, created_by, HISTORY_TYPES[:close_contact], comment)
  end

  def self.close_contact_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a close contact.')
    create_history(patient, created_by, HISTORY_TYPES[:close_contact_edit], comment)
  end

  def self.contact_attempt(patient: nil, created_by: 'Sara Alert System', comment: 'The system attempted to make contact with the monitoree.')
    create_history(patient, created_by, HISTORY_TYPES[:contact_attempt], comment)
  end

  def self.welcome_message_sent(patient: nil, created_by: 'Sara Alert System', comment: 'Initial Sara Alert welcome message was sent.')
    create_history(patient, created_by, HISTORY_TYPES[:welcome_message_sent], comment)
  end

  def self.record_automatically_closed(patient: nil, created_by: 'Sara Alert System', comment: 'Monitoree has completed monitoring.')
    create_history(patient, created_by, HISTORY_TYPES[:record_automatically_closed], comment)
  end

  def self.monitoring_status(history)
    field = {
      name: 'Monitoring Status',
      old_value: history[:patient_before][:monitoring] ? 'Monitoring' : 'Not Monitoring',
      new_value: history[:updates][:monitoring] ? 'Monitoring' : 'Not Monitoring'
    }

    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.exposure_risk_assessment(history)
    field = {
      name: 'Exposure Risk Assessment',
      old_value: history[:patient_before][:exposure_risk_assessment],
      new_value: history[:updates][:exposure_risk_assessment]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.monitoring_plan(history)
    field = {
      name: 'Monitoring Plan',
      old_value: history[:patient_before][:monitoring_plan],
      new_value: history[:updates][:monitoring_plan]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.case_status(history, diff_state)
    field = {
      name: 'Case Status',
      old_value: history[:patient_before][:case_status],
      new_value: history[:updates][:case_status]
    }
    return if field[:old_value] == field[:new_value]

    if !history[:updates][:monitoring].blank? && !history[:updates][:monitoring]
      # monitoree went from actively monitoring to not monitoring
      history[:note] = ', and chose to "End Monitoring"'
      # monitoree went from exposure to isolation (only applies to when user deliberately selected to continue monitoring in isolation workflow)
    elsif !history[:patient_before][:isolation].present? && history[:updates][:isolation].present? && !diff_state.nil? && diff_state.include?(:isolation)
      history[:note] = ', and chose to "Continue Monitoring in Isolation Workflow"'
    end

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.public_health_action(history)
    field = {
      name: 'Latest Public Health Action',
      old_value: history[:patient_before][:public_health_action],
      new_value: history[:updates][:public_health_action]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.jurisdiction(history)
    field = {
      name: 'Jurisdiction',
      old_value: Jurisdiction.find(history[:patient_before][:jurisdiction_id])[:path],
      new_value: Jurisdiction.find(history[:updates][:jurisdiction_id])[:path]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.assigned_user(history)
    field = {
      name: 'Assigned User',
      old_value: history[:patient_before][:assigned_user],
      new_value: history[:updates][:assigned_user]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.pause_notifications(history)
    field = {
      name: 'Notification Status',
      old_value: history[:patient_before][:pause_notifications] ? 'paused' : 'resumed',
      new_value: history[:updates][:pause_notifications] ? 'paused' : 'resumed'
    }
    return if field[:old_value] == field[:new_value]

    creator = history[:household_status] == :patient ? 'User' : 'System'
    comment = "#{creator} #{field[:new_value]} notifications for this monitoree#{compose_explanation(history, field)}."
    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], comment)
  end

  def self.symptom_onset(history)
    field = {
      name: 'Symptom Onset Date',
      type: 'date',
      old_value: history[:patient_before][:symptom_onset]&.to_date&.strftime('%m/%d/%Y'),
      new_value: history[:updates][:symptom_onset]&.to_date&.strftime('%m/%d/%Y')
    }
    return if field[:old_value] == field[:new_value]

    comment = compose_message(history, field)
    comment += ' The system will now populate this date.' if field[:new_value].nil?
    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], comment)
  end

  def self.last_date_of_exposure(history)
    field = {
      name: 'Last Date of Exposure',
      type: 'date',
      old_value: history[:patient_before][:last_date_of_exposure]&.to_date&.strftime('%m/%d/%Y'),
      new_value: history[:updates][:last_date_of_exposure]&.to_date&.strftime('%m/%d/%Y')
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
  end

  def self.continuous_exposure(history)
    field = {
      name: 'Continuous Exposure',
      old_value: history[:patient_before][:continuous_exposure] ? 'on' : 'off',
      new_value: history[:updates][:continuous_exposure] ? 'on' : 'off'
    }
    return if field[:old_value] == field[:new_value]

    creator = history[:household_status] == :patient ? 'User' : 'System'
    comment = "#{creator} turned #{field[:new_value]} #{field[:name]}#{compose_explanation(history, field)}."
    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], comment)
  end

  def self.extended_isolation(history)
    field = {
      name: 'Extended Isolation',
      type: 'date',
      old_value: history[:patient_before][:extended_isolation]&.to_date&.strftime('%m/%d/%Y'),
      new_value: history[:updates][:extended_isolation]&.to_date&.strftime('%m/%d/%Y')
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field))
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

    patient = patient.id if patient.respond_to?(:id)
    History.create!(created_by: created_by, comment: comment, patient_id: patient, history_type: type)
  end

  private_class_method def self.compose_message(history, field)
    creator = history[:household_status] == :patient ? 'User' : 'System'
    verb = field[:new_value].blank? ? 'cleared' : 'changed'
    from_text = field[:old_value].blank? ? 'blank' : "\"#{field[:old_value]}\""
    to_text = field[:new_value].blank? ? 'blank' : "\"#{field[:new_value]}\""

    comment = "#{creator} #{verb} #{field[:name]} from #{from_text} to #{to_text}"
    comment += compose_explanation(history, field)
    comment += history[:note] unless history[:note].blank?
    comment += '.'
    comment += " Reason: #{history[:reason]}" unless history[:reason].blank?
    comment
  end

  private_class_method def self.compose_explanation(history, field)
    if history[:household_status] == :patient && history[:propagation] == :group
      " and chose to update this #{field[:type]} for all household members"
    elsif history[:household_status] == :patient && history[:propagation] == :group_cm
      " and chose to update this #{field[:type]} for household members under continuous exposure"
    elsif history[:household_status] != :patient && history[:propagation] == :group
      " because User updated #{field[:name]} for another member in this monitoree's household and chose to update this
        #{field[:type].nil? ? 'field' : field[:type]} for all household members"
    elsif history[:household_status] != :patient && history[:propagation] == :group_cm
      " because User updated #{field[:name]} for another member in this monitoree's household and chose to update this
        #{field[:type].nil? ? 'field' : field[:type]} for household members under continuous exposure"
    else
      ''
    end
  end
end
