# frozen_string_literal: true

# Generated exports for downloads in the API
class ApiDownload < ApplicationRecord
  has_many_attached :files
end
