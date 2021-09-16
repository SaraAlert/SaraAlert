# frozen_string_literal: true

# PatientMailer: mailers for monitorees
class PatientMailer < ApplicationMailer
  def enrollment_email(patient)
    # Should not be sending enrollment email if no valid email
    return if patient&.email.blank?

    # Gather patients and jurisdictions
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    @patients = patient.active_dependents.uniq.map do |dependent|
      { patient: dependent, jurisdiction_unique_id: Jurisdiction.find_by_id(dependent.jurisdiction_id).unique_identifier }
    end
    @lang = patient.select_language(:email)
    @contact_info = patient.jurisdiction.contact_info
    mail(to: patient.email&.strip, subject: I18n.t('assessments.html.email.enrollment.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    History.welcome_message_sent(patient: patient)
  end

  def assessment_email(patient)
    if patient&.email.blank?
      patient.add_report_reminder_fail_history_blank_field('email')
      return
    end

    # Cover potential race condition where multiple messages are sent for the same monitoree.
    # Do not send an assessment when patient's last_assessment_reminder_sent is set or a reminder was sent less than 12 hours ago.
    return unless patient.last_assessment_reminder_sent_eligible?

    @lang = patient.select_language(:email)
    @contact_info = patient.jurisdiction.contact_info
    # Gather patients and jurisdictions
    # patient.dependents includes the patient themselves if patient.id = patient.responder_id (which should be the case)
    @patients = patient.active_dependents.uniq.map do |dependent|
      { patient: dependent, jurisdiction_unique_id: Jurisdiction.find_by_id(dependent.jurisdiction_id).unique_identifier }
    end
    # Update last send attempt timestamp before SMTP call
    patient.last_assessment_reminder_sent = DateTime.now
    patient.save(touch: false)
    mail(to: patient.email&.strip, subject: I18n.t('assessments.html.email.reminder.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    patient.active_dependents_and_self.each { |_pat| patient.add_report_reminder_success_history }
  # This method is called in in the main loop of the send_assessments_job
  # It is important to capture and log all errors and let the loop continue to send assessments
  rescue StandardError => e
    # Reset send attempt timestamp on failure
    patient.last_assessment_reminder_sent = nil
    patient.save(touch: false)
    # report_email_error History will not update associated patient updated_at
    History.report_email_error(patient: patient)
    Raven.capture_exception(e)
  end

  def closed_email(patient)
    if patient&.email.blank?
      History.send_close_contact_method_blank(patient: patient, type: 'email')
      return
    end

    @lang = patient.select_language(:email)
    @contents = I18n.t(
      'assessments.html.email.closed.thank_you',
      initials_age: patient&.initials_age('-'),
      completed_date: patient.closed_at&.strftime('%m-%d-%Y'),
      locale: @lang
    )
    mail(to: patient.email&.strip, subject: I18n.t('assessments.html.email.closed.subject', locale: @lang)) do |format|
      format.html { render layout: 'main_mailer' }
    end
    History.monitoring_complete_message_sent(patient: patient)
  end
end
