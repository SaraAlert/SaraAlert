# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'dashboard_verifier'

class MonitoreeEnrollmentDashboard < ApplicationSystemTestCase
  @@monitoree_enrollment_dashboard_verifier = MonitoreeEnrollmentDashboardVerifier.new(nil)
  
  def view_enrollment_analytics(jurisdiction_id)
    click_on 'Analytics'
    @@monitoree_enrollment_dashboard_verifier.verify_enrollment_analytics(jurisdiction_id)
  end
end
