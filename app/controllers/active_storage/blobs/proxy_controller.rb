# frozen_string_literal: true

# Proxy files through application with authentication.
# This avoids making the S3 bucket where files are stored public

# This controller is heavily customized for Exports. When Rails 7 is released, these changes can get incorporated into the Downloads controller itself.
# Rails 7 is expected to have features related to making it possible to stream files without having to overwrite this controller.
# This will allow us to remove the custom authentication and delete job queuing.

# Overwriting
# https://github.com/rails/rails/blob/6-1-stable/activestorage/app/controllers/active_storage/blobs/proxy_controller.rb
class ActiveStorage::Blobs::ProxyController < ActiveStorage::BaseController
  include ActiveStorage::SetBlob
  include ActiveStorage::SetHeaders
  include ActionController::Live

  before_action :authenticate_user!, :authorize_user!

  def show
    http_cache_forever public: true do
      set_content_headers_from @blob
      stream @blob
    end
  ensure
    # Enqueue delete job after it's done being sent
    download = @blob&.attachments&.first&.record
    queue_destroy_download(download) unless Rails.configuration.x.executing_system_tests
  end

  private

  def authenticate_user!
    super
  rescue UncaughtThrowError => e
    # This is what should be happening anyway in ApplicationController.
    # Due to https://github.com/heartcombo/devise/issues/2332
    # Override `authenticate_user!` to handle the uncaught throw.
    redirect_to('/') && return if e.message.ends_with?(':warden')

    raise e
  end

  def authorize_user!
    redirect_to('/') && return if current_user.nil? || !current_user.can_export? || current_user&.id != @blob&.attachments&.first&.record&.user_id
  end

  def queue_destroy_download(download)
    DestroyDownloadsJob.set(wait_until: ADMIN_OPTIONS['download_destroy_wait_time'].to_i.minute.from_now).perform_later(download)
    download.update(marked_for_deletion: true)
  end
end
