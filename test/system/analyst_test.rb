# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/analytics/monitoree_counts_verifier'
require_relative 'lib/analytics/monitoree_snapshots_verifier'
require_relative 'lib/system_test_utils'

class AnalystTest < ApplicationSystemTestCase
  @@analytics_monitoree_counts_verifier = AnalyticsMonitoreeCountsVerifier.new(nil)
  @@analytics_monitoree_snapshots_verifier = AnalyticsMonitoreeSnapshotsVerifier.new(nil)
  @@system_test_utils = SystemTestUtils.new(nil)

  test 'view analytics as different types of users' do
    view_analytics('analyst_all')
    view_analytics('state1_epi')
    view_analytics('locals1c1_epi')
    view_analytics('state1_epi_enroller')
  end

  test 'export analysis as png' do
    trigger_export_buttons('state1_epi')
  end

  def view_analytics(user_name)
    jurisdiction_id = login_and_view_analytics(user_name)
    analytic_id = Analytic.where(jurisdiction_id: jurisdiction_id).order(created_at: :desc).first['id']
    @@analytics_monitoree_counts_verifier.verify_monitoree_counts(analytic_id)
    @@analytics_monitoree_snapshots_verifier.verify_monitoree_snapshots(analytic_id)
    @@system_test_utils.logout
  end

  def trigger_export_buttons(user_name)
    login_and_view_analytics(user_name)
    click_on 'EXPORT ANALYSIS AS PNG'
    click_on 'Export Complete Country Data'
    @@system_test_utils.logout
  end

  def login_and_view_analytics(user_name)
    jurisdiction_id = @@system_test_utils.login(user_name)
    click_on 'Analytics' if !user_name.include? 'analyst'
    jurisdiction_id
  end
end
