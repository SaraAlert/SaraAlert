# frozen_string_literal: true

# DownloadsController: for handling user downloads
class DownloadsController < ApplicationController
  before_action :authenticate_user!

  def download
    redirect_to root_url unless current_user.can_export?
    lookup = params[:lookup]
    download = current_user.downloads.find_by(lookup: lookup)
    if download.nil?
      @error = true
    else
      send_data(Base64.decode64(download.contents), filename: download.filename) && download.delete
    end
  end
end
