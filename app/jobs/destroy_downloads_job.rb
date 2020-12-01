# frozen_string_literal: true

class DestroyDownloadsJob < ApplicationJob
  queue_as :default

  def perform(download)
    download.destroy
  end
end
