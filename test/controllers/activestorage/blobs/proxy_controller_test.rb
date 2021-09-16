# frozen_string_literal: true

require 'test_case'

class ActiveStorage::Blobs::ProxyControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:public_health_user)
    @download = create(:download, user_id: @user.id)
    @download.export_files.attach(io: StringIO.new('text'), filename: 'text.txt', content_type: 'application/text')
    @download_url = rails_storage_proxy_path(@download.export_files.first, only_path: true)
  end

  test 'user that requested export can download' do
    sign_in @user
    get @download_url
    assert_response :success
  end

  test 'user that did not request export cannot download' do
    other_user = create(:public_health_user)
    sign_in other_user
    get @download_url
    assert_redirected_to '/'
  end

  test 'non-logged in user cannot download export' do
    get @download_url
    assert_response :unauthorized
  end

  test 'non-logged in user cannot download export that does not have an associated user' do
    # Corner case download without user relationship
    download = create(:download, user_id: nil)
    download.export_files.attach(io: StringIO.new('text'), filename: 'text.txt', content_type: 'application/text')
    download_url = rails_storage_proxy_path(download.export_files.first, only_path: true)
    sign_in @user
    get download_url
    assert_redirected_to '/'
  end
end
