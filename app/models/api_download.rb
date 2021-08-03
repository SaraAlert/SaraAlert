# frozen_string_literal: true

# Generated exports for downloads in the API
class ApiDownload < ApplicationRecord
  belongs_to :application, class_name: 'OauthApplication'
  has_many_attached :files
end
