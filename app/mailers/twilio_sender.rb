# frozen_string_literal: true

# TwilioSender: Methods to interact with Twilio REST API
class TwilioSender
  @client = Twilio::REST::Client.new(ENV['TWILLIO_API_ACCOUNT'], ENV['TWILLIO_API_KEY'])
  def self.send_sms(patient, contents)
    from = ENV['TWILLIO_MESSAGING_SERVICE_SID'] || ENV['TWILLIO_SENDING_NUMBER']
    begin
      @client.messages.create(
        to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
        body: contents,
        from: from
      )
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      return false
    end
    true
  end

  def self.start_studio_flow(patient, params)
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
    phone_number_from = message&.[]('From')
    phone_number_to = message&.[]('To')

    return { monitoree_number: phone_number_from, sara_number: phone_number_to } if !phone_number_from.nil? && !phone_number_to.nil?

    nil
  end
end
