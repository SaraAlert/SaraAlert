# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../public_health_monitoring/history_verifier'

class PublicHealthMonitoringHistory < ApplicationSystemTestCase  
  @@public_health_monitoring_history_verifier = PublicHealthMonitoringHistoryVerifier.new(nil)
  
  def add_comment(user_name, comment)
    fill_in 'comment', with: comment
    click_on 'Add Comment'
    @@public_health_monitoring_history_verifier.verify_comment(user_name, comment)
  end
end
