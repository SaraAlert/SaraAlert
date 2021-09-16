# frozen_string_literal: true

module Twilio
  # Contains constants and method for working with Twilio error codes.
  module TwilioErrorCodes
    CODES = {
      invalid_to_number: { code: '21211', message: 'Invalid recipient phone number.' },
      blocked_number: { code: '21610', message: 'Recipient phone number blocked communication with Sara Alert' },
      invalid_number: { code: '21614', message: 'Invalid recipient phone number.' },
      unsupported_region: { code: '21408', message: 'Recipient phone number is in an unsupported region.' },
      unreachable_unavailable: { code: '30003', message: 'Recipient phone is off, may not be eligible to receive SMS messages, or is otherwise unavailable.' },
      unavailable_ineligible: { code: '30004',
                                message: 'Recipient may have blocked communications with SaraAlert, recipient phone may be unavailable or ineligible '\
                                'to receive SMS text messages.' },
      non_existent_or_off: { code: '30005',
                             message: 'Recipient phone number may not exist, the phone may be off or the phone is not eligible to receive SMS text messages.' },
      sms_ineligible: { code: '30006',
                        message: 'Recipient phone number may not be eligible to receive SMS text messages, or the carrier network may be unreachable.' },
      carrier_filter: { code: '30007', message: 'Message has been filtered by carrier network.' },
      unknown_error: { code: '30008',
                       message: '30008' }
    }.freeze

    def self.handle_twilio_error_codes(patient, error_code)
      if error_code == CODES[:blocked_number][:code] && !BlockedNumber.exists?(phone_number: patient.primary_telephone)
        BlockedNumber.create(phone_number: patient.primary_telephone)
      end
      err_msg = CODES.find do |_k, v|
                  v[:code] == error_code
                end&.second&.[](:message) || error_code
      dispatch_errored_contact_history_items(patient, err_msg)
    end

    def self.retry_eligible_error_codes
      CODES.values_at(:unreachable_unavailable).pluck(:code)
    end

    def self.dispatch_errored_contact_history_items(patient, error_message)
      pats = if patient&.responder_id == patient.id && (patient.preferred_contact_method != 'SMS Texted Weblink')
               # If errored contact was for a communication for all dependents ie: sms_assessment or voice_assessment
               patient&.active_dependents_and_self
             else
               # If errored contact was for a particular dependent ie: weblink assessment
               [patient, patient&.responder]
             end
      History.unsuccessful_report_reminder_group_of_patients(patients: pats, error_message: error_message)
    end
  end
end
