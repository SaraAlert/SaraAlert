# frozen_string_literal: true

# DownloadsController: for handling user downloads
class DownloadsController < ApplicationController
  include Rails.application.routes.url_helpers
  before_action :authenticate_user!

  def download
    redirect_to root_url unless current_user.can_export?
    @download = current_user.downloads.find_by(id: params[:id])
    @export_url = rails_blob_url(@download.exports.first)
  end

  # Hit this endpoint after the download link is clicked to remove download from database
  # and object storage
  def downloaded
    byebug
    download = current_user.downloads.find_by(id: params.permit(:id)[:id])
    DestroyDownloadsJob.set(wait_until: 1.hour.from_now).perform_later(download) unless download.marked_for_deletion
    download.update(marked_for_deletion: true)
  end
end
