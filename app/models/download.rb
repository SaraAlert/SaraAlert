# frozen_string_literal: true

class Download < ApplicationRecord
  has_many_attached :exports
end
