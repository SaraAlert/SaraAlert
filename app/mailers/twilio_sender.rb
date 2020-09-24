# frozen_string_literal: true

# TwilioSender: Methods to interact with Twilio REST API
class TwilioSender
  def self.send_sms(patient, contents)
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_MESSAGING_SERVICE_SID'] || ENV['TWILLIO_SENDING_NUMBER']
    begin
      client = Twilio::REST::Client.new(account_sid, auth_token)

      client.messages.create(
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
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_MESSAGING_SERVICE_SID'] || ENV['TWILLIO_SENDING_NUMBER']
    begin
      client = Twilio::REST::Client.new(account_sid, auth_token)
      client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
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
end
