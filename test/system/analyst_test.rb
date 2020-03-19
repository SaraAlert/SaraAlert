# frozen_string_literal: true

require 'application_system_test_case'

require_relative 'lib/system_test_utils'

class AnalystTest < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def setup
    Jurisdiction.find_each do |jur|
      empty_analytic = Analytic.create(
        monitorees_count: 0,
        symptomatic_monitorees_count: 0,
        asymptomatic_monitorees_count: 0,
        confirmed_cases_count: 0,
        closed_cases_count: 0,
        open_cases_count: 0,
        total_reports_count: 0,
        non_reporting_monitorees_count: 0,
        monitoree_state_map: {},
        symptomatic_state_map: {}
      )
      jur.analytics.push(empty_analytic)
    end
  end

  test 'analyst viewing analytics' do
    login_and_view_analytics('analyst_all', true)
  end

  test 'epi viewing analytics' do
    login_and_view_analytics('state1_epi', false)
    login_and_view_analytics('locals1c1_epi', false)
  end

  test 'epi enroller viewing analytics' do
    login_and_view_analytics('state1_epi_enroller', false)
  end

  def login_and_view_analytics(user_name, is_analyst)
    @@system_test_utils.login(user_name)
    click_on 'Analytics' unless is_analyst
    verify_analytics_page
    @@system_test_utils.logout
  end

  def verify_analytics_page
    ## verify jurisdiction
    assert_selector 'button', text: 'EXPORT ANALYSIS AS PNG'
  end
end
