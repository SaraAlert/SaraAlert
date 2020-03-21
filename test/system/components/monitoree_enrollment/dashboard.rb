# frozen_string_literal: true

require 'application_system_test_case'

require_relative '../../lib/system_test_utils'

class MonitoreeEnrollmentDashboard < ApplicationSystemTestCase
  @@system_test_utils = SystemTestUtils.new(nil)

  def login_and_view_enrollment_analytics(user_name)
    @@system_test_utils.login(user_name)
    click_on 'Analytics'
    assert_equal('/analytics', page.current_path)
    click_on 'Return to Dashboard'
    assert_equal('/patients', page.current_path)
  end
end
