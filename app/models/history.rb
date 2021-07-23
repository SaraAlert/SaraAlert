# frozen_string_literal: true

require 'action_view'
require 'action_view/helpers'

# History: history model
class History < ApplicationRecord
  include ExcelSanitizer
  include FhirHelper

  HISTORY_TYPES = {
    record_edit: 'Record Edit',
    system_record_edit: 'System Record Edit',
    report_created: 'Report Created',
    report_updated: 'Report Updated',
    comment: 'Comment',
    enrollment: 'Enrollment',
    monitoring_change: 'Monitoring Change',
    follow_up_flag: 'Follow Up Flag',
    monitoree_data_downloaded: 'Monitoree Data Downloaded',
    reports_reviewed: 'Reports Reviewed',
    report_reviewed: 'Report Reviewed',
    report_reminder: 'Report Reminder',
    unsuccessful_report_reminder: 'Unsuccessful Report Reminder',
    report_note: 'Report Note',
    lab_result: 'Lab Result',
    lab_result_edit: 'Lab Result Edit',
    vaccination: 'Vaccination',
    vaccination_edit: 'Vaccination Edit',
    close_contact: 'Close Contact',
    close_contact_edit: 'Close Contact Edit',
    contact_attempt: 'Contact Attempt',
    welcome_message_sent: 'Welcome Message Sent',
    record_automatically_closed: 'Record Automatically Closed',
    monitoring_complete_message_sent: 'Monitoring Complete Message Sent',
    assessment_email_error: 'Assessment Email Error'
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
  belongs_to :original_comment, class_name: 'History', optional: true

  # Patient updated_at should not be updated if history was created by:
  # - report_reminder
  # - monitoree data download
  # - unsuccessful_report_reminder
  # - assessment_email_error
  after_create(
    proc do
      patient.touch unless [
        HISTORY_TYPES[:report_reminder],
        HISTORY_TYPES[:monitoree_data_downloaded],
        HISTORY_TYPES[:unsuccessful_report_reminder],
        HISTORY_TYPES[:assessment_email_error]
      ].include? history_type
    end
  )

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

  # Histories created between the given time range that are user driven (not system, or enrollment)
  scope :user_generated_between, lambda { |start, finish|
    where('created_at >= ?', start)
      .where('created_at <= ?', finish)
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

  # Histories that indicate a record was moved from isolation to exposure
  scope :isolation_to_exposure, lambda {
    where('comment like ?', '%moved from isolation to exposure workflow%')
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

  def as_fhir
    history_as_fhir(self)
  end

  def self.unsuccessful_report_reminder_group_of_patients(patients: nil, created_by: 'Sara Alert System', comment: 'Failed Contact Attempt', error_message: nil)
    histories = []
    patients.uniq.each do |pat|
      if pat.responder == pat
        recipient = 'this monitoree'
        responder = pat
      else
        recipient = "this monitoree's head of household"
        responder = pat.responder
      end
      details = error_message.present? ? ' Error details: ' + error_message : ''
      comment = if responder&.preferred_contact_method&.include?('SMS')
                  "Sara Alert attempted to send an SMS to #{recipient} at #{responder.primary_telephone}, but the message could not be delivered.#{details}"
                else
                  "Sara Alert attempted to call #{recipient} at #{responder.primary_telephone}, but the call could not be completed.#{details}"
                end
      histories << History.new(created_by: created_by, comment: comment, patient_id: pat.id, history_type: HISTORY_TYPES[:unsuccessful_report_reminder])
    end
    History.import! histories
  end

  def self.record_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a record.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:record_edit], comment, create: create)
  end

  def self.report_created(patient: nil, created_by: 'Sara Alert System', comment: 'User created a new report.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:report_created], comment, create: create)
  end

  def self.report_updated(patient: nil, created_by: 'Sara Alert System', comment: 'User updated existing report.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:report_updated], comment, create: create)
  end

  def self.enrollment(patient: nil, created_by: 'Sara Alert System', comment: 'User enrolled monitoree.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:enrollment], comment, create: create)
  end

  def self.monitoring_change(patient: nil, created_by: 'Sara Alert System', comment: 'User updated monitoree.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:monitoring_change], comment, create: create)
  end

  def self.monitoree_data_downloaded(patient: nil, created_by: 'Sara Alert System', comment: 'User downloaded monitoree\'s data in Excel Export.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:monitoree_data_downloaded], comment, create: create)
  end

  def self.reports_reviewed(patient: nil, created_by: 'Sara Alert System', comment: 'User reviewed all reports.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:reports_reviewed], comment, create: create)
  end

  def self.report_reviewed(patient: nil, created_by: 'Sara Alert System', comment: 'User reviewed a report.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:report_reviewed], comment, create: create)
  end

  def self.report_reminder(patient: nil, created_by: 'Sara Alert System', comment: 'User sent a report reminder to the monitoree.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:report_reminder], comment, create: create)
  end

  def self.unsuccessful_report_reminder(patient: nil, created_by: 'Sara Alert System', comment: 'Unsuccessful report reminder.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:unsuccessful_report_reminder], comment, create: create)
  end

  def self.vaccination(patient: nil, created_by: 'Sara Alert System', comment: 'User added a new vaccination.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:vaccination], comment, create: create)
  end

  def self.vaccination_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a vaccination.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:vaccination_edit], comment, create: create)
  end

  def self.lab_result(patient: nil, created_by: 'Sara Alert System', comment: 'User added a new lab result.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:lab_result], comment, create: create)
  end

  def self.lab_result_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a lab result.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:lab_result_edit], comment, create: create)
  end

  def self.close_contact(patient: nil, created_by: 'Sara Alert System', comment: 'User added a new close contact.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:close_contact], comment, create: create)
  end

  def self.close_contact_edit(patient: nil, created_by: 'Sara Alert System', comment: 'User edited a close contact.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:close_contact_edit], comment, create: create)
  end

  def self.contact_attempt(patient: nil, created_by: 'Sara Alert System', comment: 'The system attempted to make contact with the monitoree.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:contact_attempt], comment, create: create)
  end

  def self.welcome_message_sent(patient: nil, created_by: 'Sara Alert System', comment: 'Initial Sara Alert welcome message was sent.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:welcome_message_sent], comment, create: create)
  end

  def self.record_automatically_closed(patient: nil, created_by: 'Sara Alert System', comment: 'Monitoree has completed monitoring.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:record_automatically_closed], comment, create: create)
  end

  def self.monitoring_complete_message_sent(patient: nil, created_by: 'Sara Alert System', comment: 'Monitoring Complete message was sent.', create: true)
    create_history(patient, created_by, HISTORY_TYPES[:monitoring_complete_message_sent], comment, create: create)
  end

  def self.calculated_symptom_onset(patient: nil, created_by: 'Sara Alert System', new_symptom_onset: nil, action: 'created')
    return if patient[:symptom_onset] == new_symptom_onset

    comment = if patient[:symptom_onset].present? && new_symptom_onset.present?
                "System changed Symptom Onset Date from #{patient[:symptom_onset].strftime('%m/%d/%Y')} to #{new_symptom_onset.strftime('%m/%d/%Y')}
                because a report meeting the symptomatic logic was #{action}."
              elsif patient[:symptom_onset].nil? && new_symptom_onset.present?
                "System changed Symptom Onset Date from blank to #{new_symptom_onset.strftime('%m/%d/%Y')}
                because a report meeting the symptomatic logic was #{action}."
              elsif patient[:symptom_onset].present? && new_symptom_onset.nil?
                "System cleared Symptom Onset Date from #{patient[:symptom_onset].strftime('%m/%d/%Y')} to blank
                because a report meeting the symptomatic logic was #{action}."
              end

    create_history(patient, created_by, HISTORY_TYPES[:monitoring_change], comment, create: create)
  end

  def self.send_close_conact_method_blank(patient: nil, created_by: 'Sara Alert System', type: 'Unknown', create: true)
    comment = "The system was unable to send a monitoring complete message to this monitoree because their preferred contact method, #{type}, was blank."
    create_history(patient, created_by, HISTORY_TYPES[:monitoring_complete_message_sent], comment, create: create)
  end

  def self.send_close_sms_blocked(patient: nil, created_by: 'Sara Alert System', create: true)
    comment = 'The system was unable to send a monitoring complete message to this monitoree'\
              ' because the recipient phone number blocked communication with Sara Alert'
    create_history(patient, created_by, HISTORY_TYPES[:monitoring_complete_message_sent], comment, create: create)
  end

  def self.assessment_email_error(patient: nil,
                                  created_by: 'Sara Alert System',
                                  comment: 'Sara Alert was unable to send a report email to the monitoree because of an unexpected error.',
                                  create: true)
    create_history(patient, created_by, HISTORY_TYPES[:assessment_email_error], comment, create: create)
  end

  def self.monitoring_status(history, create: true)
    field = {
      name: 'Monitoring Status',
      old_value: history[:patient_before][:monitoring] ? 'Monitoring' : 'Not Monitoring',
      new_value: history[:updates][:monitoring] ? 'Monitoring' : 'Not Monitoring'
    }

    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.exposure_risk_assessment(history, create: true)
    field = {
      name: 'Exposure Risk Assessment',
      old_value: history[:patient_before][:exposure_risk_assessment],
      new_value: history[:updates][:exposure_risk_assessment]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.monitoring_plan(history, create: true)
    field = {
      name: 'Monitoring Plan',
      old_value: history[:patient_before][:monitoring_plan],
      new_value: history[:updates][:monitoring_plan]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.case_status(history, diff_state, create: true)
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

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.public_health_action(history, create: true)
    field = {
      name: 'Latest Public Health Action',
      old_value: history[:patient_before][:public_health_action],
      new_value: history[:updates][:public_health_action]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.jurisdiction(history, create: true)
    field = {
      name: 'Jurisdiction',
      old_value: Jurisdiction.find(history[:patient_before][:jurisdiction_id])[:path],
      new_value: Jurisdiction.find(history[:updates][:jurisdiction_id])[:path]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.assigned_user(history, create: true)
    field = {
      name: 'Assigned User',
      old_value: history[:patient_before][:assigned_user],
      new_value: history[:updates][:assigned_user]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.pause_notifications(history)
    field = {
      name: 'Notification Status',
      old_value: history[:patient_before][:pause_notifications] ? 'paused' : 'resumed',
      new_value: history[:updates][:pause_notifications] ? 'paused' : 'resumed'
    }
    return if field[:old_value] == field[:new_value]

    creator = history[:initiator_id].nil? ? 'System' : 'User'
    comment = "#{creator} #{field[:new_value]} notifications for this monitoree#{compose_explanation(history)}."
    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], comment)
  end

  def self.symptom_onset(history, create: true)
    field = {
      name: 'Symptom Onset Date',
      type: 'date',
      old_value: history[:patient_before][:symptom_onset]&.to_date&.strftime('%m/%d/%Y'),
      new_value: history[:updates][:symptom_onset]&.to_date&.strftime('%m/%d/%Y')
    }
    return if field[:old_value] == field[:new_value]

    comment = compose_message(history, field)
    comment += ' The system will now populate this date.' if field[:new_value].nil?
    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], comment, create: create)
  end

  def self.last_date_of_exposure(history, create: true)
    field = {
      name: 'Last Date of Exposure',
      type: 'date',
      old_value: history[:patient_before][:last_date_of_exposure]&.to_date&.strftime('%m/%d/%Y'),
      new_value: history[:updates][:last_date_of_exposure]&.to_date&.strftime('%m/%d/%Y')
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.continuous_exposure(history)
    field = {
      name: 'Continuous Exposure',
      old_value: history[:patient_before][:continuous_exposure] ? 'on' : 'off',
      new_value: history[:updates][:continuous_exposure] ? 'on' : 'off'
    }
    return if field[:old_value] == field[:new_value]

    creator = history[:initiator_id].nil? ? 'System' : 'User'
    comment = "#{creator} turned #{field[:new_value]} #{field[:name]}#{compose_explanation(history)}."
    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], comment)
  end

  def self.monitoring_reason(history, create: true)
    field = {
      name: 'Reason for Closure',
      old_value: history[:patient_before][:monitoring_reason],
      new_value: history[:updates][:monitoring_reason]
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.extended_isolation(history, create: true)
    field = {
      name: 'Extended Isolation',
      type: 'date',
      old_value: history[:patient_before][:extended_isolation]&.to_date&.strftime('%m/%d/%Y'),
      new_value: history[:updates][:extended_isolation]&.to_date&.strftime('%m/%d/%Y')
    }
    return if field[:old_value] == field[:new_value]

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:monitoring_change], compose_message(history, field), create: create)
  end

  def self.follow_up_flag_edit(history, create: true)
    return if history[:follow_up_reason] == history[:follow_up_reason_before] && history[:follow_up_note] == history[:follow_up_note_before]

    comment = 'User flagged for follow-up'
    comment += compose_explanation(history) + '.'
    comment += " Reason: \"#{history[:follow_up_reason]}"
    comment += ": #{history[:follow_up_note]}" unless history[:follow_up_note].blank?
    comment += '"'

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:follow_up_flag], comment, create: create)
  end

  def self.clear_follow_up_flag(history, create: true)
    return if history[:follow_up_reason_before].nil?

    comment = 'User cleared flag for follow-up'
    comment += compose_explanation(history) + '.'
    comment += " Reason: #{history[:clear_flag_reason]}" unless history[:clear_flag_reason].blank?

    create_history(history[:patient], history[:created_by], HISTORY_TYPES[:follow_up_flag], comment, create: create)
  end

  private_class_method def self.create_history(patient, created_by, type, comment, create: true)
    return if patient.nil?

    patient = patient.id if patient.respond_to?(:id)
    if create
      History.create!(created_by: created_by, comment: comment, patient_id: patient, history_type: type)
    else
      History.new(created_by: created_by, comment: comment, patient_id: patient, history_type: type)
    end
  end

  private_class_method def self.compose_message(history, field)
    verb = field[:new_value].blank? ? 'cleared' : 'changed'
    from_text = field[:old_value].blank? ? 'blank' : "\"#{field[:old_value]}\""
    to_text = field[:new_value].blank? ? 'blank' : "\"#{field[:new_value]}\""

    comment = "User #{verb} #{field[:name]} from #{from_text} to #{to_text}"
    comment += compose_explanation(history)
    comment += history[:note] unless history[:note].blank?
    comment += '.'
    comment += " Reason: #{history[:reason]}" unless history[:reason].blank?
    comment
  end

  private_class_method def self.compose_explanation(history)
    if history[:initiator_id] == history[:patient].id && history[:propagation] == :group
      ' and applied that change to all household members'
    elsif history[:initiator_id] == history[:patient].responder_id && history[:propagation] == :group
      " by making that change to monitoree's Head of Household (Sara Alert ID: #{history[:initiator_id]})"\
      ' and to all household members'
    elsif history[:initiator_id] != history[:patient].id && history[:initiator_id] == history[:patient].responder_id
      " by making that change to monitoree's Head of Household (Sara Alert ID: #{history[:initiator_id]})"\
      ' and to this monitoree'
    elsif history[:initiator_id] != history[:patient].id
      " by making that change to a household member (Sara Alert ID: #{history[:initiator_id]})"\
      ' and to this monitoree'
    else
      ''
    end
  end
end
