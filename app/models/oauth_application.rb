# frozen_string_literal: true

# OauthApplication: Custom class on top of Doorkeeper Application mixin
class OauthApplication < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
  has_many :jwt_identifiers, foreign_key: 'application_id', dependent: :destroy
  has_many :api_downloads, foreign_key: 'application_id'
  belongs_to :jurisdiction, optional: true

  def exported_recently?
    api_downloads.where('created_at > ?', Rails.configuration.api['bulk_export_retry_after_minutes'].minutes.ago).exists?
  end

  def retry_bulk_export_after
    api_downloads.pluck(:created_at).last + Rails.configuration.api['bulk_export_retry_after_minutes'].minutes
  end
end
