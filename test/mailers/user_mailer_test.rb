# frozen_string_literal: true

require 'test_case'

class UserMailerTest < ActionMailer::TestCase
  def setup
    @user = create(:user)
  end

  test 'download email no lookups' do
    # When no monitorees match export criteria lookups = []
    email = UserMailer.download_email(@user, 'Export Label', []).deliver_now
    email_body = email.parts.first.body.to_s.gsub("\n", ' ')
    assert_not(ActionMailer::Base.deliveries.empty?)
    assert_includes(email_body, 'Export Label')
    assert_includes(email_body, 'no monitorees or monitoree data matched the selected export criteria')
  end
end
