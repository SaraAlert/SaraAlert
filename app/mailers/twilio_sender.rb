# frozen_string_literal: true

# TwilioSender: Methods to interact with Twilio REST API
class TwilioSender
  @client = Twilio::REST::Client.new(ENV['TWILLIO_API_ACCOUNT'], ENV['TWILLIO_API_KEY'])
  def self.handle_twilio_error_codes(patient, error_code)
    case error_code
    # SaraAlert code for unsupported voice language
    when 'SA1'
      History.errored_contact_attempt_hoh_and_dependents(patient,
                                                         error_message: 'Sara Alert does not support voice assessments in the monitorees primary language.')
    # Invalid To Number https://www.twilio.com/docs/api/errors/21211
    when '21211'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: 'Invalid recipient phone number.')
    # Blocked Number Error https://www.twilio.com/docs/api/errors/21610
    when '21610'
      PatientMailer.add_fail_history_sms_blocked(patient)
    # Invalid Mobile Number Error https://www.twilio.com/docs/api/errors/21614
    when '21614'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: 'Invalid recipient phone number.')
    # Unsupported Region Error https://www.twilio.com/docs/api/errors/21408
    when '21408'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: 'Recipient phone number is in an unsupported region.')
    # Unreachable Destination Handset Error https://www.twilio.com/docs/api/errors/30003
    when '30003'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: 'Recipient phone is off or otherwise unavailable.')
    # Message Blocked Error https://www.twilio.com/docs/api/errors/30004
    when '30004'
      error_message = 'Recipient may have blocked communications with SaraAlert,recipient phone may be unavilable or inelligible to recieve SMS text messages.'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: error_message)
    # Unknown Destination Handset Error https://www.twilio.com/docs/api/errors/30005
    when '30005'
      error_message = 'Recipient phone number may not exist, the phone may be off or the phone is not eligible to receive SMS text messages.'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: error_message)
    # Landline or Unreachable Carrier Error https://www.twilio.com/docs/api/errors/30006
    when '30006'
      error_message = 'Recipient phone number may not eligible to receive SMS text messages, or carrier network may be unreachable.'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: error_message)
    # Message Filtered By Carrier Error https://www.twilio.com/docs/api/errors/30007
    when '30007'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: 'Message has been filtered by carrier network.')
    # Unknown Error https://www.twilio.com/docs/api/errors/30008
    when '30008'
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: 'An unknown error has been encountered by the messaging system.')
    else
      History.errored_contact_attempt_hoh_and_dependents(patient, error_message: 'An unknown error has been encountered by the messaging system.')
    end
  end

  def self.send_sms(patient, params)
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
      # The error codes will be caught here in cases where a messaging service is not used
      error_code = e&.code&.to_s
      handle_twilio_error_codes(patient, error_code)
      return
    end

    # Get a message out of the studio execution which we can get the To/From numbers out of
    # The opt-in/out could come from an incoming message trigger OR an existing execution
    # The message pulled from an existing execution will be the first inbound message found within the execution
    message = execution&.context&.[]('trigger')&.[]('message') || execution&.context&.[]('widgets')&.values&.select do |x|
                                                                    x&.[]('inbound')
                                                                  end&.[](0)&.[]('inbound')
    phone_number_from = message&.[]('From')
    phone_number_to = message&.[]('To')

    return { monitoree_number: phone_number_from, sara_number: phone_number_to } if !phone_number_from.nil? && !phone_number_to.nil?

    nil
  end
end
