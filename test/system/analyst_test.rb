require "application_system_test_case"

require_relative "lib/system_test_utils"

class AnalystTest < ApplicationSystemTestCase

  @@system_test_utils = SystemTestUtils.new(nil)

  USERS = @@system_test_utils.get_users

  test "analyst viewing analytics" do
    login_and_view_analytics(USERS["analyst_all"], true)
  end

  test "epi viewing analytics" do
    login_and_view_analytics(USERS["state1_epi"], false)
    login_and_view_analytics(USERS["locals1c1_epi"], false)
  end

  test "epi enroller viewing analytics" do
    login_and_view_analytics(USERS["state1_epi_enroller"], false)
  end

  def login_and_view_analytics(user, is_analyst)
    @@system_test_utils.login(user)
    if !is_analyst
      click_on "Analytics"
    end
    verify_analytics_page(user)
    @@system_test_utils.logout
  end

  def verify_analytics_page(user)
    ## verify jurisdiction
    assert_selector "button", text: "EXPORT ANALYSIS AS PNG"
    assert_selector "h5", text: "System Statistics"
    assert_selector "h5", text: "Symptomatic Monitorees"
    assert_selector "h5", text: "Total Assessments Over Time"
    assert_selector "h5", text: "Total Monitorees"
    assert_selector "h5", text: "Monitoring Distribution by Day"
  end

end
