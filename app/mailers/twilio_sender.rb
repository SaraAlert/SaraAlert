class TwilioSender

  def self.send_sms(patient, contents)
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    messaging_service_sid = ENV['TWILLIO_MESSAGING_SERVICE_SID']

    client = Twilio::REST::Client.new(account_sid, auth_token)

    if messaging_service_sid.present?
      client.messages.create(
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents,
      messaging_service_sid: messaging_service_sid
      )
    else
      client.messages.create(
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      body: contents,
      from: from
      )
    end
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      patient.update(last_assessment_reminder_sent: DateTime.now)
      return false
    true
  end

  def self.start_studio_flow(patient, params)
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    from = ENV['TWILLIO_SENDING_NUMBER']
    messaging_service_sid = ENV['TWILLIO_MESSAGING_SERVICE_SID']

    client = Twilio::REST::Client.new(account_sid, auth_token)

    if messaging_service_sid.present? || params[:medium] != 'VOICE'
      client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      parameters: params,
      messaging_service_sid: messaging_service_sid
      )
    else
      client.studio.v1.flows(ENV['TWILLIO_STUDIO_FLOW']).executions.create(
      to: Phonelib.parse(patient.primary_telephone, 'US').full_e164,
      parameters: params,
      from: from
      )
    end
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      patient.update(last_assessment_reminder_sent: DateTime.now)
      return false
    true
  end

end