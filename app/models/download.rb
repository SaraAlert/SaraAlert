# frozen_string_literal: true

# Generated exports for download
class Download < ApplicationRecord
  has_many_attached :export_files
end
