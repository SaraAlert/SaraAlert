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
      patient.update(last_assessment_reminder_sent: DateTime.now)
      return false
    end
    true
  end

  def self.start_studio_flow(patient, params)
    from = ENV['TWILLIO_MESSAGING_SERVICE_SID'] || ENV['TWILLIO_SENDING_NUMBER']
    begin
      @client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
        to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
        parameters: params,
        from: from
      )
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      patient.update(last_assessment_reminder_sent: DateTime.now)
      return false
    end
    true
  end

  def self.get_responder_from_flow_execution(execution_id)
    begin
      execution = @client.studio.v1
                         .flows(ENV['TWILLIO_STUDIO_FLOW'])
                         .executions(execution_id)
                         .fetch
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      return
    end
    phone_number = execution.contact_channel_address
    Patient.responder_for_number(phone_number)
  end
end
