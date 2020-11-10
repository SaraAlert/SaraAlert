# frozen_string_literal: true

# UserExportPreset: a saved user export preset
class UserExportPreset < ApplicationRecord
  belongs_to :user
end
