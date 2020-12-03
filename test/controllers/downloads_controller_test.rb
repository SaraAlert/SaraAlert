# frozen_string_literal: true

require 'test_case'

class DownloadsControllerTest < ActionController::TestCase
  test 'download' do
    user = create(:public_health_user)
    download = create(:download, user_id: user.id)
    text = StringIO.new('text')
    download.exports.attach(io: text, filename: 'text.txt', content_type: 'application/text')
    sign_in user
    get :download, params: { id: download.id }
    assert_response :success
  end

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
