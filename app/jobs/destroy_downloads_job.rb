# frozen_string_literal: true

# Destroy a download, currently launched from the DownloadsController after a link is clicked.
class DestroyDownloadsJob < ApplicationJob
  queue_as :default

  def perform(download)
    download.destroy
  end
end
