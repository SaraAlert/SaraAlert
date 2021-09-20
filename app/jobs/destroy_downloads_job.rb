# frozen_string_literal: true

# Destroy a download, currently launched from the DownloadsController after a link is clicked.
class DestroyDownloadsJob < ApplicationJob
  queue_as :exports

  def perform(download_id)
    Download.find(download_id).destroy if Download.exists?(download_id)
  end
end
