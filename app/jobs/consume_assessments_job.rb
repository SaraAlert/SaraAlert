# frozen_string_literal: true

# ConsumeAssessmentsJorker: Pulls assessments created in the split instance and saves them
class ConsumeAssessmentsJob
  include Sidekiq::Worker
  sidekiq_options queue: :assessments, retry: 2

  def perform(msg)
    message = JSON.parse(msg)&.slice('threshold_condition_hash',
                                     'reported_symptoms_array',
                                     'patient_submission_token',
                                     'experiencing_symptoms',
                                     'response_status',
                                     'error_code')
    # Invalid message
    if message.empty?
      log_and_capture('ConsumeAssessmentsJob: No valid fields found in message. Skipping.')
      return
    end

    if message['response_status'].in?(%w[opt_out opt_in])
      handle_opt_in_opt_out(message)
      return
    end

    patient = Patient.where(purged: false).find_by(submission_token: message['patient_submission_token'])

    # Perform patient lookup for old submission tokens if new token does not find a Patient
    if patient.nil?
      patient_lookup = PatientLookup.find_by(old_submission_token: message['patient_submission_token'])
      patient = Patient.find_by(submission_token: patient_lookup[:new_submission_token]) unless patient_lookup.nil?
      # If new and old submission token does not find a Patient, stop processing
      if patient.nil?
        log_and_capture("ConsumeAssessmentsJob: No patient found with submission_token: #{message['patient_submission_token']}", sentry: false)
        return
      end
    end

    # Error occured in twilio studio flow
    if message['error_code'].present?
      TwilioSender.handle_twilio_error_codes(patient, message['error_code'])
      # Will attempt to resend assessment if phone is off
      patient.update(last_assessment_reminder_sent: nil) if message['error_code']&.in?(TwilioSender.retry_eligible_error_codes)
      return
    end

    # Prevent duplicate patient assessment spam
    # Only check for latest assessment if there is one
    if !patient.latest_assessment.nil? && (patient.latest_assessment.created_at > ADMIN_OPTIONS['reporting_limit'].minutes.ago)
      log_and_capture("ConsumeAssessmentsJob: Skipping duplicate assessment (patient: #{patient.id})", sentry: false)
      return
    end

    # Get list of dependents excluding the patient itself.
    dependents = patient.dependents_exclude_self

    case message['response_status']
    when 'no_answer_voice'
      # If nobody answered, nil out the last_reminder_sent field so the system will try calling again
      patient.update(last_assessment_reminder_sent: nil)
      History.contact_attempt(patient: patient, comment: "Sara Alert called this monitoree's primary telephone" \
                              " number #{patient.primary_telephone} and nobody answered the phone.")
      if dependents.present?
        create_contact_attempt_history_for_dependents(dependents, "Sara Alert called this monitoree's head" \
                                              ' of household and nobody answered the phone.')
      end

      return
    when 'no_answer_sms'
      # No need to wipe out last_assessment_reminder_sent so that another sms will be sent because the sms studio flow is kept open for 18hrs
      History.contact_attempt(patient: patient, comment: "Sara Alert texted this monitoree's primary telephone" \
                              " number #{patient.primary_telephone} during their preferred" \
                              ' contact time, but did not receive a response.')
      if dependents.present?
        create_contact_attempt_history_for_dependents(dependents, "Sara Alert texted this monitoree's head of" \
                                              ' household and did not receive a response.')
      end

      return
    when 'error_voice'
      # If there was an error in completeing the call, nil out the last_reminder_sent field so the system will try calling again
      patient.update(last_assessment_reminder_sent: nil)
      History.contact_attempt(patient: patient, comment: 'Sara Alert was unable to complete a call to this' \
                             " monitoree's primary telephone number #{patient.primary_telephone}.")
      if dependents.present?
        create_contact_attempt_history_for_dependents(dependents, 'Sara Alert was unable to complete a call' \
                                              " to this monitoree's head of household.")
      end

      return
    when 'error_sms'
      History.contact_attempt(patient: patient, comment: "Sara Alert was unable to send an SMS to this monitoree's" \
                              " primary telephone number #{patient.primary_telephone}.")
      if dependents.present?
        create_contact_attempt_history_for_dependents(dependents, 'Sara Alert was unable to send an SMS to' \
                                              " this monitoree's head of household.")
      end

      return
    when 'max_retries_sms'
      # Maximum amount of SMS response retries reached
      History.contact_attempt(patient: patient, comment: 'The system could not record a response because the monitoree exceeded the maximum number' \
                              " of daily report SMS response retries via primary telephone number #{patient.primary_telephone}.")
      if dependents.present?
        create_contact_attempt_history_for_dependents(dependents, "The system could not record a response because the monitoree's head of household" \
          " exceeded the maximum number of daily report SMS response retries via primary telephone number #{patient.primary_telephone}.")
      end

      return
    when 'max_retries_voice'
      # Maximum amount of voice response retries reached
      History.contact_attempt(patient: patient, comment: 'The system could not record a response because the monitoree exceeded the maximum number' \
        " of report voice response retries via primary telephone number #{patient.primary_telephone}.")
      if dependents.present?
        create_contact_attempt_history_for_dependents(dependents, "The system could not record a response because the monitoree's head of household" \
          " exceeded the maximum number of report voice response retries via primary telephone number #{patient.primary_telephone}.")
      end

      return
    end

    threshold_condition = ThresholdCondition.find_by(threshold_condition_hash: message['threshold_condition_hash'])
    # Invalid threshold_condition_hash
    if threshold_condition.nil?
      log_and_capture("ConsumeAssessmentsJob: No ThresholdCondition found (patient: #{patient.id}, " \
                      "threshold_condition_hash: #{message['threshold_condition_hash']})")
      return
    end

    if message['reported_symptoms_array']
      typed_reported_symptoms = Condition.build_symptoms(message['reported_symptoms_array'])
      reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
      assessment = Assessment.new(reported_condition: reported_condition, patient: patient, who_reported: 'Monitoree')
      begin
        reported_condition.transaction do
          reported_condition.save!
          assessment.symptomatic = assessment.symptomatic?
          assessment.save!
        end
      rescue ActiveRecord::RecordInvalid => e
        log_and_capture("ConsumeAssessmentsJob: Unable to save assessment. Patient ID: #{patient.id}. Error: #{e}")
      end
    else
      # If message['reported_symptoms_array'] is not populated then this assessment came in through
      # a generic channel ie: SMS where monitorees are asked YES/NO if they are experiencing symptoms
      patient.active_dependents.each do |dependent|
        typed_reported_symptoms = if message['experiencing_symptoms']
                                    # Remove values so that the values will appear as blank in a symptomatic report
                                    # this will indicate that the person needs to be reached out to to get the actual values
                                    threshold_condition.clone_symptoms_remove_values
                                  else
                                    # The person is not experiencing symptoms, we can infer that the bool symptoms are the opposite
                                    # of the threshold values that represent symptomatic
                                    threshold_condition.clone_symptoms_negate_bool_values
                                  end
        reported_condition = ReportedCondition.new(symptoms: typed_reported_symptoms, threshold_condition_hash: message['threshold_condition_hash'])
        assessment = Assessment.new(reported_condition: reported_condition, patient: dependent)

        # If current user in the collection of patient + patient dependents is the patient, then that means
        # that they reported for themselves, else we are creating an assessment for the dependent and
        # that means that it was the proxy who reported for them
        assessment.who_reported = patient.submission_token == dependent.submission_token ? 'Monitoree' : 'Proxy'
        begin
          reported_condition.transaction do
            reported_condition.save!
            assessment.symptomatic = assessment.symptomatic? || message['experiencing_symptoms']
            assessment.save!
          end
        rescue ActiveRecord::RecordInvalid => e
          log_and_capture("ConsumeAssessmentsJob: Unable to save assessment. Patient ID: #{patient.id}. Error: #{e}")
        end
      end
    end
  rescue JSON::ParserError
    # Do not reproduce entire message in the log. There may be sensitive data in the message.
    # Sentry will automatically capture.
    Rails.logger.error('ConsumeAssessmentsJob: Skipping invalid message.')
  end

  private

  def log_and_capture(msg, sentry: true)
    Rails.logger.info(msg)
    Raven.capture_message(msg) if sentry
  end

  def handle_opt_in_opt_out(message)
    # When an opt_in or opt_out response_status is posted to us the patient_submission_token value is popuated with
    # a flow execution id, this is because a monitoree may send STOP/START outside the context of an assessment and
    # therefore the patient.submission_token will not be available. We get the responder associated with the opt_in
    # or opt_out phone number by requesting the phone number who sent the message in the associated flow execution id
    phone_numbers = TwilioSender.get_phone_numbers_from_flow_execution(message['patient_submission_token'])
    if phone_numbers.nil?
      Rails.logger.info(
        "ConsumeAssessmentsJob: failure fetching number for opt-in/opt-out message (message response status: #{message['response_status']})"
      )
      return
    end

    monitoree_number = Phonelib.parse(phone_numbers[:monitoree_number], 'US').full_e164
    sara_number = phone_numbers[:sara_number]
    # Handle BlockedNumber manipulation here in case no monitorees are associated with this number
    BlockedNumber.create(phone_number: monitoree_number) if message['response_status'] == 'opt_out'
    BlockedNumber.where(phone_number: monitoree_number).destroy_all if message['response_status'] == 'opt_in'
    patients = Patient.responder_for_number(monitoree_number)
    patients.each do |patient|
      next if patient.nil?

      # Get list of dependents excluding the patient itself.
      dependents = patient.dependents_exclude_self

      case message['response_status']
      when 'opt_out'
        # In cases of opt_in/opt_out the sara_number should always be available
        sara_number ||= '<Number Unavailable>'
        History.contact_attempt(patient: patient, comment: "The system will no longer be able to send an SMS to this monitoree #{patient.primary_telephone},
          because the monitoree blocked communications with Sara Alert by sending a STOP keyword to #{sara_number}.")
        if dependents.present?
          create_contact_attempt_history_for_dependents(dependents, "The system will no longer be able to send an SMS to this monitoree's head of household
            #{patient.primary_telephone}, because the head of household blocked communications with Sara Alert by sending a STOP keyword to #{sara_number}.")
        end
      when 'opt_in'
        # In cases of opt_in/opt_out the sara_number should always be available
        sara_number ||= '<Number Unavailable>'
        History.contact_attempt(patient: patient, comment: "The system will now be able to send an SMS to this monitoree #{patient.primary_telephone},
          because the monitoree re-enabled communications with Sara Alert by sending a START keyword to #{sara_number}.")

        if dependents.present?
          create_contact_attempt_history_for_dependents(dependents, "The system will now be able to send an SMS to this monitoree's head of household
            #{patient.primary_telephone}, because the head of household re-enabled communications with Sara Alert by sending a START
            keyword to #{sara_number}.")
        end
      end
    end
  end

  # Use the import method here to generate less SQL statements for a bulk insert of
  # dependent histories instead of 1 statement per dependent.
  def create_contact_attempt_history_for_dependents(dependents, comment)
    histories = []
    dependents.each do |dependent|
      histories << History.new(patient: dependent,
                               created_by: 'Sara Alert System',
                               comment: comment,
                               history_type: 'Contact Attempt')
    end
    History.import! histories
  end
end
