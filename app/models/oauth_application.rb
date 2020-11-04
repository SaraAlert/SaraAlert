# frozen_string_literal: true

# OauthApplication: Custom class on top of Doorkeeper Application mixin
class OauthApplication < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::Application
  has_many :jwt_identifiers, foreign_key: 'application_id', dependent: :destroy
  belongs_to :jurisdiction, optional: true
end
