# frozen_string_literal: true

require 'test_case'

class DownloadsControllerTest < ActionController::TestCase
  test 'downloaded' do
    user = create(:public_health_user)
    download = create(:download, user_id: user.id)
    sign_in user

    assert_difference 'Download.count', -1 do
      post :downloaded, params: {
        id: download.id
      }
    end
  end
end
