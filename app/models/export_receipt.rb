# frozen_string_literal: true

# ExportReceipt: represents an export receipt
class ExportReceipt < ApplicationRecord
  belongs_to :user
end
