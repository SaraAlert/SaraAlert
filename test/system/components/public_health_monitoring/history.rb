require "application_system_test_case"

class PublicHealthMonitoringHistory < ApplicationSystemTestCase

  def add_comment(comment)
    fill_in "comment", with: comment
    click_on "Add Comment"
  end

end