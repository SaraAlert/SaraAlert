# frozen_string_literal: true

# TwilioSender: Methods to interact with Twilio REST API
class TwilioSender
  TWILIO_ERROR_CODES = {
    invalid_to_number: '21211',
    blocked_number: '21610',
    invalid_number: '21614',
    unsupported_region: '21408',
    unreachable_unavailable: '30003',
    unavailable_ineligible: '30004',
    non_existent_or_off: '30005',
    sms_ineligible: '30006',
    carrier_filter: '30007',
    unknown_error: '30008'
  }.freeze

  @client = Twilio::REST::Client.new(ENV['TWILLIO_API_ACCOUNT'], ENV['TWILLIO_API_KEY'])
  def self.handle_twilio_error_codes(patient, error_code)
    case error_code
    # Invalid To Number https://www.twilio.com/docs/api/errors/21211
    when TWILIO_ERROR_CODES[:invalid_to_number]
      dispatch_errored_contact_history_items(patient, 'Invalid recipient phone number.')
    # Blocked Number Error https://www.twilio.com/docs/api/errors/21610
    when TWILIO_ERROR_CODES[:blocked_number]
      dispatch_errored_contact_history_items(patient, 'Recipient phone number blocked communication with Sara Alert')
      monitoree_number = Phonelib.parse(phone_numbers[:monitoree_number], 'US').full_e164
      BlockedNumber.create(phone_number: monitoree_number) unless BlockedNumber.exists?(phone_number: monitoree_number)
    # Invalid Mobile Number Error https://www.twilio.com/docs/api/errors/21614
    when TWILIO_ERROR_CODES[:invalid_number]
      dispatch_errored_contact_history_items(patient, 'Invalid recipient phone number.')
    # Unsupported Region Error https://www.twilio.com/docs/api/errors/21408
    when TWILIO_ERROR_CODES[:unsupported_region]
      dispatch_errored_contact_history_items(patient, 'Recipient phone number is in an unsupported region.')
    # Unreachable Destination Handset Error https://www.twilio.com/docs/api/errors/30003
    when TWILIO_ERROR_CODES[:unreachable_unavailable]
      error_message = 'Recipient phone is off, may not be eligible to receive SMS messages, or is otherwise unavailable.'
      dispatch_errored_contact_history_items(patient, error_message)
    # Message Blocked Error https://www.twilio.com/docs/api/errors/30004
    when TWILIO_ERROR_CODES[:unavailable_ineligible]
      error_message = 'Recipient may have blocked communications with SaraAlert, recipient phone may be unavailable or ineligible to receive SMS text messages.'
      dispatch_errored_contact_history_items(patient, error_message)
    # Unknown Destination Handset Error https://www.twilio.com/docs/api/errors/30005
    when TWILIO_ERROR_CODES[:non_existent_or_off]
      error_message = 'Recipient phone number may not exist, the phone may be off or the phone is not eligible to receive SMS text messages.'
      dispatch_errored_contact_history_items(patient, error_message)
    # Landline or Unreachable Carrier Error https://www.twilio.com/docs/api/errors/30006
    when TWILIO_ERROR_CODES[:sms_ineligible]
      error_message = 'Recipient phone number may not eligible to receive SMS text messages, or carrier network may be unreachable.'
      dispatch_errored_contact_history_items(patient, error_message)
    # Message Filtered By Carrier Error https://www.twilio.com/docs/api/errors/30007
    when TWILIO_ERROR_CODES[:carrier_filter]
      dispatch_errored_contact_history_items(patient, 'Message has been filtered by carrier network.')
    # Unknown Error https://www.twilio.com/docs/api/errors/30008
    when TWILIO_ERROR_CODES[:unknown_error]
      error_message = 'An unknown error has been encountered by the messaging system. '
      error_message += 'The system will retry in an hour if it is still in monitoree’s preferred contact period.'
      dispatch_errored_contact_history_items(patient, error_message)
    else
      dispatch_errored_contact_history_items(patient, 'An unknown error has been encountered by the messaging system.')
    end
  end

  def self.retry_eligible_error_codes
    TWILIO_ERROR_CODES.values_at(:unreachable_unavailable)
  end

  # send_sms takes an array of patients for cases where messages for multiple patients need to
  # be sent to a single patient at the same time ie: weblinks for all of a HoHs dependents
  def self.send_sms(patient, messages)
    params = { messages_array: messages, medium: 'SINGLE_SMS' }
    from = ENV['TWILLIO_MESSAGING_SERVICE_SID'] || ENV['TWILLIO_SENDING_NUMBER']
    begin
      @client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
        to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
        parameters: params,
        from: from
      )
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      # The error codes will be caught here in cases where a messaging service is not used
      error_code = e&.code&.to_s
      handle_twilio_error_codes(patient, error_code)
      return false
    end
    true
  end

  def self.start_studio_flow_assessment(patient, params)
    # Studio API trigger does not support use of messaging service SID for calls
    from = if params[:medium] == 'VOICE'
             ENV['TWILLIO_SENDING_NUMBER']
           else
             ENV['TWILLIO_MESSAGING_SERVICE_SID'] || ENV['TWILLIO_SENDING_NUMBER']
           end

    begin
      @client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
        to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
        parameters: params,
        from: from
      )
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      # The error codes will be caught here in cases where a messaging service is not used
      error_code = e&.code&.to_s
      handle_twilio_error_codes(patient, error_code)
      return false
    end
    true
  end

  def self.get_phone_numbers_from_flow_execution(execution_id)
    begin
      execution = @client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions(execution_id).execution_context.fetch
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      return
    end
    # Get a message out of the studio execution which we can get the To/From numbers out of
    # The opt-in/out could come from an incoming message trigger OR an existing execution
    # The message pulled from an existing execution will be the first inbound message found within the execution
    message = execution&.context&.[]('trigger')&.[]('message') || execution&.context&.[]('widgets')&.values&.select do |x|
                                                                    x&.[]('inbound')
                                                                  end&.[](0)&.[]('inbound')
    # Alternatively, the execution could be of type SINGLE_SMS where we sent a single outbound message
    message = execution&.context&.[]('widgets')&.values&.select { |x| x&.[]('To') }&.[](0) if message.nil?

    return nil if message.nil?

    if !message&.[]('outbound').nil? || (message&.[]('Direction')&.include? 'outbound')
      phone_number_from = message&.[]('To')
      phone_number_to = message&.[]('From')
    else
      phone_number_from = message&.[]('From')
      phone_number_to = message&.[]('To')
    end

    return { monitoree_number: phone_number_from, sara_number: phone_number_to } if !phone_number_from.nil? && !phone_number_to.nil?

    nil
  end

  def self.dispatch_errored_contact_history_items(patient, error_message)
    pats = if patient&.responder_id == patient.id && (patient.preferred_contact_method != 'SMS Texted Weblink')
             # If errored contact was for a communication for all dependents ie: sms_assessment or voice_assessment
             patient&.active_dependents_and_self
           else
             # If errored contact was for a particular dependent ie: weblink assessment
             [patient, patient&.responder]
           end
    History.errored_report_reminder_group_of_patients(patients: pats, error_message: error_message)
  end
end
