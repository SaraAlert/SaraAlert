require 'twilio-ruby'

module TwillioHelper
  def self.send_enrollment_sms(patient)
    @patient = patient
    # TODO: Figure out why root_url doesn't work here to get server location
    contents = "This is the DiseaseTrakker system please complete your assessment at http://localhost:3000/patients/#{@patient.id}/assessments/new"
    account_sid = ENV['TWILLIO_API_ACCOUNT']
    auth_token = ENV['TWILLIO_API_KEY']
    client = Twilio::REST::Client.new(account_sid, auth_token)

    from = '+18167448873' # Your Twilio number

    client.messages.create(
    from: from,
    to: @patient.primary_phone,
    body: contents
    )
  end
end