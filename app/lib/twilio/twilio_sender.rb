# frozen_string_literal: true

# Module for everything Twilio
module Twilio
  # TwilioSender: Methods to interact with Twilio REST API
  class TwilioSender
    include TwilioErrorCodes

    @client = Twilio::REST::Client.new(ENV['TWILLIO_API_ACCOUNT'], ENV['TWILLIO_API_KEY'])
    @flow = ENV['TWILLIO_STUDIO_FLOW']

    class << self
      attr_reader :client, :flow
    end

    attr_reader :from, :to, :medium
    attr_accessor :error_code

    def initialize(medium, primary_telephone)
      @medium = medium
      # Studio API trigger does not support use of messaging service SID for calls
      @from = if medium == 'VOICE'
                ENV['TWILLIO_SENDING_NUMBER']
              else
                ENV['TWILLIO_MESSAGING_SERVICE_SID'] || ENV['TWILLIO_SENDING_NUMBER']
              end
      @to = Phonelib.parse(primary_telephone, 'US').full_e164
    end

    def create_execution(params)
      TwilioSender.client.studio.v1.flows(TwilioSender.flow).executions.create(
        to: @to,
        parameters: params,
        from: @from
      )
      true
    rescue Twilio::REST::RestError => e
      Rails.logger.warn e.error_message
      # The error codes will be caught here in cases where a messaging service is not used
      @error_code = e&.code&.to_s
      false
    end

    def self.get_phone_numbers_from_flow_execution(execution_id)
      begin
        execution = TwilioSender.client.studio.v1.flows(TwilioSender.flow).executions(execution_id).execution_context.fetch
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
  end
end
